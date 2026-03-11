import { LightningElement, api } from 'lwc';

export default class CpqProgressBar extends LightningElement {
    @api currentStep = 1;
    @api steps = []; // [{ number, key, label, icon }]

    get computedSteps() {
        return this.steps.map(s => {
            const isCurrent = s.number === this.currentStep;
            const isComplete = s.number < this.currentStep;
            const isClickable = s.number <= this.currentStep;

            return {
                ...s,
                isCurrent,
                isComplete,
                itemClass: [
                    'slds-progress__item',
                    isComplete ? 'slds-is-completed' : '',
                    isCurrent ? 'slds-is-active' : ''
                ].filter(Boolean).join(' '),
                buttonClass: [
                    'slds-progress__marker',
                    isComplete ? 'slds-progress__marker_icon' : ''
                ].filter(Boolean).join(' '),
                isClickable
            };
        });
    }

    get progressValue() {
        const total = this.steps.length;
        if (total <= 1) return 0;
        return Math.round(((this.currentStep - 1) / (total - 1)) * 100);
    }

    get progressStyle() {
        return `width: ${this.progressValue}%`;
    }

    handleStepClick(event) {
        const stepNumber = parseInt(event.currentTarget.dataset.step, 10);
        if (stepNumber <= this.currentStep) {
            this.dispatchEvent(new CustomEvent('stepnavigate', {
                detail: { step: stepNumber }
            }));
        }
    }

    handleStepKeydown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.handleStepClick(event);
        }
    }
}
