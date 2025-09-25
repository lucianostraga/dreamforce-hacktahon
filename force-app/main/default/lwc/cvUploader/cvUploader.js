import { LightningElement, api } from 'lwc';
import analyzeCV from '@salesforce/apex/CVAnalyzerController.analyzeCV';

export default class CvUploader extends LightningElement {
    @api positionId;

    fileName = '';
    fileSize = '';
    isProcessing = false;
    blobString = '';
    isAnalyzing = false;

    connectedCallback() {
        console.log('CV Uploader initialized with Position ID:', this.positionId);
    }

    handleFileChange(event) {
        const file = event.target.files[0];
        if (file) {
            this.fileName = file.name;
            this.fileSize = this.formatFileSize(file.size);
            this.isProcessing = true;

            const reader = new FileReader();
            reader.onload = () => {
                const base64 = reader.result;
                // Extract only the base64 data part (remove the data URL prefix)
                this.blobString = base64.split(',')[1];
                this.isProcessing = false;

                console.log('File converted to base64:', {
                    filename: file.name,
                    size: file.size,
                    type: file.type,
                    base64Length: this.blobString.length,
                    base64Preview: this.blobString.substring(0, 100) + '...'
                });
            };
            reader.onerror = () => {
                this.isProcessing = false;
                this.showNotification('Error', 'Failed to read file', 'error');
            };
            reader.readAsDataURL(file);
        }
    }

    handleAnalyze() {
        if (!this.blobString) {
            this.showNotification('Warning', 'Please select a file first', 'warning');
            return;
        }

        this.isAnalyzing = true;

        console.log('Sending to Apex:', {
            fileName: this.fileName,
            blobStringLength: this.blobString.length,
            positionId: this.positionId
        });

        analyzeCV({
            blobString: this.blobString,
            fileName: this.fileName,
            positionId: this.positionId
        })
        .then(() => {
            console.log('Analysis completed successfully');
            this.dispatchEvent(new CustomEvent('fileanalysis', {
                detail: {
                    blobString: this.blobString,
                    fileName: this.fileName,
                    positionId: this.positionId
                }
            }));
            this.showNotification('Success', 'Resume analysis completed', 'success');
            this.isAnalyzing = false;
        })
        .catch(error => {
            console.error('Error analyzing CV:', error);
            this.showNotification('Error', 'Failed to analyze resume: ' + error.body.message, 'error');
            this.isAnalyzing = false;
        });
    }

    formatFileSize(bytes) {
        if (bytes === 0) return '0 Bytes';
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
    }

    showNotification(title, message, variant) {
        // For Experience Cloud, dispatch a custom event that can be handled by a parent component
        // or show a visual notification in the component itself
        console.log(`${variant.toUpperCase()}: ${title} - ${message}`);

        // Create a custom notification event for parent components to handle
        this.dispatchEvent(new CustomEvent('notification', {
            detail: {
                title: title,
                message: message,
                variant: variant
            },
            bubbles: true,
            composed: true
        }));
    }

    get hasFile() {
        return this.blobString !== '';
    }

    get uploadLabel() {
        return this.fileName || 'Drop your PDF here or click to browse';
    }

    handleDragOver(event) {
        event.preventDefault();
        event.currentTarget.classList.add('drag-over');
    }

    handleDragLeave(event) {
        event.currentTarget.classList.remove('drag-over');
    }

    handleDrop(event) {
        event.preventDefault();
        event.currentTarget.classList.remove('drag-over');
        const files = event.dataTransfer.files;
        if (files.length > 0) {
            const file = files[0];
            const allowedTypes = ['.pdf', '.doc', '.docx'];
            const fileExtension = '.' + file.name.split('.').pop().toLowerCase();
            if (allowedTypes.includes(fileExtension)) {
                const fileInput = this.template.querySelector('lightning-input');
                fileInput.files = files;
                this.handleFileChange({ target: { files: files } });
            } else {
                this.showNotification('Error', 'Please upload PDF or Word documents only', 'error');
            }
        }
    }
}