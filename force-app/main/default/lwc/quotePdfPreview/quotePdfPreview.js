import { LightningElement, wire } from "lwc";
import { CurrentPageReference } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from "lightning/actions";
import savePDF from "@salesforce/apex/QuoteController.savePDF";

export default class QuotePdfPreview extends LightningElement {
    recordId;

    @wire(CurrentPageReference)
    wiredPageRef(pageRef) {
        if (pageRef) {
            this.recordId = pageRef.attributes.recordId || pageRef.state?.recordId;
        }
    }

    isLoading = false;
    isReady = false;
    hasError = false;
    errorMessage = "";

    get pdfUrl() {
        return "/apex/QuotePDF?id=" + (this.recordId || "");
    }

    get isNotSaving() {
        return !this.isLoading && !this.hasError;
    }

    handleSave() {
        if (!this.recordId) {
            return;
        }
        this.isLoading = true;
        this.isReady = false;

        savePDF({ quoteId: this.recordId })
            .then((savedName) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "Saved as " + savedName,
                        variant: "success"
                    })
                );
                this.dispatchEvent(new CloseActionScreenEvent());
                // Hard reload so the Quote Documents related list shows the new file.
                // Delay briefly so the success toast renders before navigation.
                setTimeout(() => window.location.reload(), 600);
            })
            .catch((error) => {
                this.isLoading = false;
                this.isReady = true;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error",
                        message:
                            error.body?.message ||
                            error.message ||
                            "Failed to save PDF.",
                        variant: "error"
                    })
                );
            });
    }

    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleIframeLoad() {
        this.isReady = true;
    }
}