import { LightningElement, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import THREEJS from '@salesforce/resourceUrl/threejs';
import LOXAM_LOGO from '@salesforce/resourceUrl/LoxamLogoWhite';
import LOXAM_LOGO_RED from '@salesforce/resourceUrl/LoxamLogoRed';


const TYPE_COLORS = { Palette: '#1f77b4', Caisse: '#ff7f0e', Carton: '#2ca02c' };
const PALETTE = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd', '#8c564b', '#e377c2', '#17becf'];

const LOXAM_RED = 0xe2001a;
const LOXAM_DARK = 0x2b2f36;

const SAMPLE = [{
    bin_data: { id: 'LRG', w: 240, h: 240, d: 600, used_space: 33.3, used_weight: 45 },
    items: [
        { id: 'Palette', coordinates: { x1: 0, y1: 0, z1: 0, x2: 120, y2: 100, z2: 80 } },
        { id: 'Palette', coordinates: { x1: 120, y1: 0, z1: 0, x2: 240, y2: 100, z2: 80 } },
        { id: 'Palette', coordinates: { x1: 0, y1: 0, z1: 80, x2: 120, y2: 100, z2: 160 } },
        { id: 'Caisse', coordinates: { x1: 120, y1: 0, z1: 80, x2: 180, y2: 60, z2: 160 } },
        { id: 'Caisse', coordinates: { x1: 180, y1: 0, z1: 80, x2: 240, y2: 60, z2: 160 } },
        { id: 'Carton', coordinates: { x1: 0, y1: 0, z1: 160, x2: 40, y2: 40, z2: 200 } },
        { id: 'Carton', coordinates: { x1: 40, y1: 0, z1: 160, x2: 80, y2: 40, z2: 200 } },
        { id: 'Carton', coordinates: { x1: 80, y1: 0, z1: 160, x2: 120, y2: 40, z2: 200 } }
    ]
}, {
    bin_data: { id: 'VAN', w: 180, h: 180, d: 300, used_space: 41.2, used_weight: 88 },
    items: [
        { id: 'Palette', coordinates: { x1: 0, y1: 0, z1: 0, x2: 120, y2: 100, z2: 80 } },
        { id: 'Palette', coordinates: { x1: 0, y1: 0, z1: 80, x2: 120, y2: 100, z2: 160 } },
        { id: 'Caisse', coordinates: { x1: 120, y1: 0, z1: 0, x2: 180, y2: 60, z2: 80 } },
        { id: 'Caisse', coordinates: { x1: 120, y1: 0, z1: 80, x2: 180, y2: 60, z2: 160 } },
        { id: 'Carton', coordinates: { x1: 0, y1: 100, z1: 0, x2: 40, y2: 140, z2: 40 } },
        { id: 'Carton', coordinates: { x1: 40, y1: 100, z1: 0, x2: 80, y2: 140, z2: 40 } }
    ]
}];

function colorForId(id) {
    if (!id) return '#888888';
    for (const key in TYPE_COLORS) {
        if (Object.prototype.hasOwnProperty.call(TYPE_COLORS, key) && id.indexOf(key) === 0) {
            return TYPE_COLORS[key];
        }
    }
    let hash = 0;
    for (let i = 0; i < id.length; i++) hash = (hash * 31 + id.charCodeAt(i)) >>> 0;
    return PALETTE[hash % PALETTE.length];
}

export default class BinPacking3dViewerGl extends LightningElement {
    @api height = 460;

    selectedBinIndex = 0;
    selectedLabel = '';
    error = '';
    viewMode = 'all'; // 'all' = every truck in one scene, 'single' = one truck via the combobox

    _bins = null;
    _loadStarted = false;
    _alive = false;

    // Three.js objects
    _THREE;
    _scene;
    _camera;
    _renderer;
    _cargo;
    _raycaster;
    _ndc;

    // Orbit state (spherical camera)
    _theta = -0.6;
    _phi = 1.0;
    _zoom = 1;
    _radius = 600;
    _drag = null;
    _raf;

    @api
    set binsJson(value) {
        try {
            this._bins = value ? JSON.parse(value) : null;
        } catch (e) {
            this._bins = null;
        }
        this.selectedBinIndex = 0;
        this.selectedLabel = '';
        if (this._scene) this._buildScene();
    }
    get binsJson() {
        return this._bins ? JSON.stringify(this._bins) : null;
    }

    get bins() {
        return this._bins && this._bins.length ? this._bins : SAMPLE;
    }
    get currentBin() {
        return this.bins[this.selectedBinIndex] || this.bins[0];
    }
    get hasMultipleBins() {
        return this.bins.length > 1;
    }
    get selectedBinValue() {
        return String(this.selectedBinIndex);
    }
    get binOptions() {
        return this.bins.map((b, i) => ({
            label: `${(b.bin_data && b.bin_data.id) || 'Truck'} #${i + 1}`,
            value: String(i)
        }));
    }
    get isAll() {
        return this.viewMode === 'all';
    }
    get isSingle() {
        return this.viewMode === 'single';
    }
    get showToggle() {
        return this.hasMultipleBins;
    }
    get showCombobox() {
        return this.isSingle && this.hasMultipleBins;
    }
    get allVariant() {
        return this.isAll ? 'brand' : 'neutral';
    }
    get singleVariant() {
        return this.isSingle ? 'brand' : 'neutral';
    }
    get containerStyle() {
        return `height:${this.height}px`;
    }
    get stageStyle() {
        // Definite height for the stage, driven by the App Builder "Viewer height" property.
        // A definite box is required so the absolutely-positioned canvas resizes predictably.
        return `height:${this.height || 460}px`;
    }
    get buildTag() {
        return 'fleet-v3';
    }
    get summary() {
        if (this.isAll && this.bins.length > 1) {
            const total = this.bins.reduce((s, b) => s + ((b.items || []).length), 0);
            return `${this.bins.length} trucks — ${total} items total`;
        }
        const bd = this.currentBin.bin_data || {};
        const count = (this.currentBin.items || []).length;
        const vol = bd.used_space != null ? `${Number(bd.used_space).toFixed(1)}% vol` : '';
        const wt = bd.used_weight != null ? ` · ${Number(bd.used_weight).toFixed(0)}% weight` : '';
        return `${bd.id || 'Truck'} — ${count} items — ${vol}${wt}`;
    }
    get legend() {
        const seen = {};
        (this.currentBin.items || []).forEach((it) => {
            if (it.id && !seen[it.id]) seen[it.id] = colorForId(it.id);
        });
        return Object.keys(seen).map((id) => ({ id, style: `background-color:${seen[id]}` }));
    }

    renderedCallback() {
        if (this._loadStarted) return;
        this._loadStarted = true;
        loadScript(this, THREEJS)
            .then(() => {
                this._THREE = window.THREE;
                if (!this._THREE) throw new Error('Three.js global not found');
                this._initThree();
                this._buildScene();
                this._alive = true;
                this._animate();
                // Record-page columns size late and over several frames. A one-shot
                // rAF re-fit fires too early; observe the stage instead so we resize
                // every time its box actually changes (incl. the first real layout).
                this._observeStage();
            })
            .catch((e) => {
                this.error = 'Unable to load the 3D viewer (Three.js/WebGL). Details: ' + (e.message || e);
            });
    }

    disconnectedCallback() {
        this._alive = false;
        if (this._raf) cancelAnimationFrame(this._raf);
        if (this._resizeObserver) {
            this._resizeObserver.disconnect();
            this._resizeObserver = null;
        }
        window.removeEventListener('mouseup', this._onUp);
        if (this._renderer) this._renderer.dispose();
    }

    handleBinChange(event) {
        this.selectedBinIndex = parseInt(event.detail.value, 10);
        this.selectedLabel = '';
        if (this._scene) this._buildScene();
    }

    showAll() {
        this.viewMode = 'all';
        this.selectedLabel = '';
        if (this._scene) this._buildScene();
    }

    showSingle() {
        this.viewMode = 'single';
        this.selectedLabel = '';
        if (this._scene) this._buildScene();
    }

    _initThree() {
        const THREE = this._THREE;
        const stage = this.template.querySelector('.stage');
        const canvas = this.template.querySelector('canvas.viewer');
        // The stage box may not be laid out yet (record-page columns size late);
        // fall back to sane defaults — the ResizeObserver re-fits once it settles.
        const w = (stage && stage.clientWidth) || 600;
        const h = (stage && stage.clientHeight) || this.height || 460;

        this._renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
        this._renderer.setPixelRatio(window.devicePixelRatio || 1);
        this._renderer.setSize(w, h, false);
        this._renderer.shadowMap.enabled = true;
        this._renderer.shadowMap.type = THREE.PCFSoftShadowMap;

        this._scene = new THREE.Scene();
        this._camera = new THREE.PerspectiveCamera(45, w / h, 1, 500000);

        this._scene.add(new THREE.AmbientLight(0xffffff, 0.7));
        const key = new THREE.DirectionalLight(0xffffff, 0.6);
        key.castShadow = true;
        key.shadow.mapSize.set(1024, 1024);
        key.shadow.bias = -0.0005;
        this._scene.add(key);
        this._key = key;
        const fill = new THREE.DirectionalLight(0xffffff, 0.25);
        fill.position.set(-1, 0.5, -1);
        this._scene.add(fill);

        // Ground plane that receives the truck shadow (repositioned per bin in _buildScene).
        this._ground = new THREE.Mesh(
            new THREE.PlaneGeometry(1000000, 1000000),
            new THREE.MeshLambertMaterial({ color: 0xeef1f4 })
        );
        this._ground.rotation.x = -Math.PI / 2;
        this._ground.receiveShadow = true;
        this._scene.add(this._ground);

        // Loxam logo textures: white logo for the trailer sides, red-background logo for the cab badge.
        this._logoTexture = new THREE.TextureLoader().load(LOXAM_LOGO);
        this._logoBadgeTexture = new THREE.TextureLoader().load(LOXAM_LOGO_RED);

        this._raycaster = new THREE.Raycaster();
        this._ndc = new THREE.Vector2();

        const el = this._renderer.domElement;
        el.addEventListener('mousedown', this._onDown);
        el.addEventListener('mousemove', this._onMove);
        el.addEventListener('wheel', this._onWheel, { passive: false });
        window.addEventListener('mouseup', this._onUp);
    }

    /**
     * Drive renderer/camera sizing from the actual stage box. A ResizeObserver fires
     * on the first real layout AND on every column/width change, which a single
     * requestAnimationFrame re-fit misses on record pages. Falls back to a one-shot
     * re-fit if ResizeObserver is unavailable.
     */
    _observeStage() {
        const stage = this.template.querySelector('.stage');
        if (!stage) return;
        if (typeof ResizeObserver === 'undefined') {
            requestAnimationFrame(() => this._onResize());
            return;
        }
        this._resizeObserver = new ResizeObserver(() => this._onResize());
        this._resizeObserver.observe(stage);
        this._onResize();
    }

    _buildScene() {
        const THREE = this._THREE;
        if (this._cargo) this._scene.remove(this._cargo);
        this._cargo = new THREE.Group();

        let span;
        let floorLevel;

        if (this.isAll && this.bins.length > 1) {
            // Fleet view: every truck lined up side by side on a common ground.
            const widths = this.bins.map((b) => (b.bin_data && b.bin_data.w) || 100);
            const maxBH = Math.max(...this.bins.map((b) => (b.bin_data && b.bin_data.h) || 100));
            const maxW = Math.max(...widths);
            const gap = maxW * 0.5;
            const total = widths.reduce((s, w) => s + w, 0) + gap * (this.bins.length - 1);
            floorLevel = -maxBH / 2;

            let cursor = -total / 2;
            let maxDepth = 0;
            this.bins.forEach((b, i) => {
                this._addTruck(b, cursor + widths[i] / 2, floorLevel);
                cursor += widths[i] + gap;
                maxDepth = Math.max(maxDepth, (b.bin_data && b.bin_data.d) || 100);
            });
            span = Math.max(total, maxDepth, maxBH);
        } else {
            // Single truck centered at the origin.
            const bd = this.currentBin.bin_data || {};
            const BH = bd.h || 100;
            floorLevel = -BH / 2;
            this._addTruck(this.currentBin, 0, floorLevel);
            span = Math.max(bd.w || 100, BH, (bd.d || 100) * 1.3);
        }

        this._scene.add(this._cargo);

        if (this._key) {
            this._key.position.set(span * 0.6, span * 1.4, span * 0.9);
            const s = span * 1.1;
            const cam = this._key.shadow.camera;
            cam.left = -s; cam.right = s; cam.top = s; cam.bottom = -s;
            cam.near = 1; cam.far = span * 6;
            cam.updateProjectionMatrix();
        }
        if (this._ground) {
            this._ground.position.y = floorLevel - Math.abs(floorLevel) * 0.4;
        }

        this._radius = span * 2.0;
        this._updateCamera();
    }

    /**
     * Adds one truck (its load + the styled vehicle) to the cargo group at offsetX,
     * with its floor at floorY. Used for both the single view and the fleet (all-trucks) view.
     */
    _addTruck(bin, offsetX, floorY) {
        const THREE = this._THREE;
        const g = new THREE.Group();
        const bd = bin.bin_data || {};
        const BW = bd.w || 100, BH = bd.h || 100, BD = bd.d || 100;
        const ox = BW / 2, oz = BD / 2;

        (bin.items || []).forEach((it) => {
            const c = it.coordinates;
            if (!c) return;
            const dw = c.x2 - c.x1, dh = c.y2 - c.y1, dd = c.z2 - c.z1;
            const geo = new THREE.BoxGeometry(dw, dh, dd);
            const mat = new THREE.MeshLambertMaterial({ color: new THREE.Color(colorForId(it.id)) });
            const mesh = new THREE.Mesh(geo, mat);
            mesh.position.set((c.x1 + c.x2) / 2 - ox, floorY + (c.y1 + c.y2) / 2, (c.z1 + c.z2) / 2 - oz);
            mesh.castShadow = true;
            mesh.userData.label = `${it.id} — ${Math.round(dw)}×${Math.round(dh)}×${Math.round(dd)} cm`
                + (bd.id ? ` · ${bd.id}` : '');
            g.add(mesh);

            const edges = new THREE.LineSegments(
                new THREE.EdgesGeometry(geo),
                new THREE.LineBasicMaterial({ color: 0x222222 })
            );
            edges.position.copy(mesh.position);
            g.add(edges);
        });

        g.add(this._buildTruck(BW, BH, BD, floorY));
        g.position.x = offsetX;
        this._cargo.add(g);
    }

    _buildTruck(BW, BH, BD, floorY) {
        const THREE = this._THREE;
        const truck = new THREE.Group();
        const cabLen = BD * 0.24;

        // Translucent Loxam-yellow cargo walls + edges (so the load stays visible).
        truck.add(new THREE.Mesh(
            new THREE.BoxGeometry(BW, BH, BD),
            new THREE.MeshLambertMaterial({ color: LOXAM_RED, transparent: true, opacity: 0.16, side: THREE.DoubleSide })
        ));
        truck.add(new THREE.LineSegments(
            new THREE.EdgesGeometry(new THREE.BoxGeometry(BW, BH, BD)),
            new THREE.LineBasicMaterial({ color: LOXAM_DARK })
        ));

        // Floor plate the load rests on.
        const plate = new THREE.Mesh(
            new THREE.BoxGeometry(BW, BH * 0.03, BD),
            new THREE.MeshLambertMaterial({ color: 0x9aa3ad })
        );
        plate.position.set(0, floorY - BH * 0.015, 0);
        plate.receiveShadow = true;
        truck.add(plate);

        // Anthracite chassis beam running under trailer + cab.
        const chassis = new THREE.Mesh(
            new THREE.BoxGeometry(BW * 0.9, BH * 0.05, BD + cabLen),
            new THREE.MeshLambertMaterial({ color: LOXAM_DARK })
        );
        chassis.position.set(0, floorY - BH * 0.05, -cabLen / 2);
        chassis.castShadow = true;
        truck.add(chassis);

        // Loxam-red cab at the front (-z).
        const cabH = BH * 0.6;
        const cab = new THREE.Mesh(
            new THREE.BoxGeometry(BW * 0.96, cabH, cabLen),
            new THREE.MeshLambertMaterial({ color: LOXAM_RED })
        );
        cab.position.set(0, floorY + cabH / 2, -BD / 2 - cabLen / 2);
        cab.castShadow = true;
        truck.add(cab);

        // Windshield.
        const glass = new THREE.Mesh(
            new THREE.BoxGeometry(BW * 0.8, cabH * 0.42, cabLen * 0.12),
            new THREE.MeshLambertMaterial({ color: 0x16344a })
        );
        glass.position.set(0, floorY + cabH * 0.66, -BD / 2 - cabLen * 0.95);
        truck.add(glass);

        // White Loxam logo decals on both trailer sides.
        if (this._logoTexture) {
            const sideMat = new THREE.MeshBasicMaterial({ map: this._logoTexture, transparent: true });
            const sideW = BD * 0.55, sideH = BH * 0.3;
            const yMid = floorY + BH * 0.55;
            [1, -1].forEach((sx) => {
                const decal = new THREE.Mesh(new THREE.PlaneGeometry(sideW, sideH), sideMat);
                decal.position.set(sx * (BW / 2 + 0.5), yMid, 0);
                decal.rotation.y = sx > 0 ? Math.PI / 2 : -Math.PI / 2;
                truck.add(decal);
            });
        }

        // Red-background Loxam badge centered on the blue windshield.
        if (this._logoBadgeTexture) {
            const badgeMat = new THREE.MeshBasicMaterial({ map: this._logoBadgeTexture, transparent: true });
            const badge = new THREE.Mesh(new THREE.PlaneGeometry(BW * 0.5, cabH * 0.2), badgeMat);
            badge.position.set(0, floorY + cabH * 0.66, -BD / 2 - cabLen * 1.06);
            badge.rotation.y = Math.PI;
            truck.add(badge);
        }

        // Wheels (tyre + light hub, axle along X).
        const rw = BH * 0.14;
        const ww = BW * 0.08;
        const tyreGeo = new THREE.CylinderGeometry(rw, rw, ww, 24);
        const tyreMat = new THREE.MeshLambertMaterial({ color: 0x141414 });
        const hubGeo = new THREE.CylinderGeometry(rw * 0.45, rw * 0.45, ww * 1.05, 16);
        const hubMat = new THREE.MeshLambertMaterial({ color: 0xb0b6bd });
        const wy = floorY - rw * 0.4;
        [-BD / 2 - cabLen * 0.5, BD * 0.05, BD * 0.32].forEach((z) => {
            [-1, 1].forEach((sx) => {
                const wheel = new THREE.Group();
                const tyre = new THREE.Mesh(tyreGeo, tyreMat);
                tyre.castShadow = true;
                wheel.add(tyre);
                wheel.add(new THREE.Mesh(hubGeo, hubMat));
                wheel.rotation.z = Math.PI / 2;
                wheel.position.set(sx * (BW / 2 - ww * 0.3), wy, z);
                truck.add(wheel);
            });
        });

        return truck;
    }

    _updateCamera() {
        const r = this._radius / this._zoom;
        const sinPhi = Math.sin(this._phi);
        this._camera.position.set(
            r * sinPhi * Math.sin(this._theta),
            r * Math.cos(this._phi),
            r * sinPhi * Math.cos(this._theta)
        );
        this._camera.lookAt(0, 0, 0);
    }

    _animate = () => {
        if (!this._alive) return;
        this._renderer.render(this._scene, this._camera);
        this._raf = requestAnimationFrame(this._animate);
    };

    _onDown = (e) => {
        this._drag = { x: e.clientX, y: e.clientY, moved: false };
    };
    _onMove = (e) => {
        if (!this._drag) return;
        const dx = e.clientX - this._drag.x;
        const dy = e.clientY - this._drag.y;
        if (Math.abs(dx) + Math.abs(dy) > 3) this._drag.moved = true;
        this._theta -= dx * 0.01;
        this._phi = Math.max(0.15, Math.min(Math.PI - 0.15, this._phi - dy * 0.01));
        this._drag.x = e.clientX;
        this._drag.y = e.clientY;
        this._updateCamera();
    };
    _onUp = (e) => {
        const wasClick = this._drag && !this._drag.moved;
        this._drag = null;
        if (wasClick) this._pick(e);
    };
    _onWheel = (e) => {
        e.preventDefault();
        this._zoom = Math.max(0.4, Math.min(3, this._zoom * (e.deltaY < 0 ? 1.1 : 0.9)));
        this._updateCamera();
    };
    _onResize = () => {
        if (!this._renderer) return;
        const stage = this.template.querySelector('.stage');
        if (!stage) return;
        const w = stage.clientWidth, h = stage.clientHeight;
        if (!w || !h) return;
        this._renderer.setSize(w, h, false);
        this._camera.aspect = w / h;
        this._camera.updateProjectionMatrix();
    };

    _pick(e) {
        const rect = this._renderer.domElement.getBoundingClientRect();
        this._ndc.x = ((e.clientX - rect.left) / rect.width) * 2 - 1;
        this._ndc.y = -((e.clientY - rect.top) / rect.height) * 2 + 1;
        this._raycaster.setFromCamera(this._ndc, this._camera);
        // Recursive: item meshes live inside per-truck groups, so we must traverse into them.
        const hits = this._raycaster.intersectObjects(this._cargo.children, true);
        const hit = hits.find((hi) => hi.object.userData && hi.object.userData.label);
        this.selectedLabel = hit ? hit.object.userData.label : '';
    }
}