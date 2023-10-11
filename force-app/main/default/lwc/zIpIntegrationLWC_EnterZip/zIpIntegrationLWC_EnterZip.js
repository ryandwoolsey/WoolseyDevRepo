import { LightningElement, wire, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import createLocationIdentifiers from "@salesforce/apex/ZipIntegrationLWCHandler.createLocationIdentifiers";
import {
    IsConsoleNavigation,
    getFocusedTabInfo,
    refreshTab
} from "lightning/platformWorkspaceApi";
import { RefreshEvent } from "lightning/refresh";

/**
 * JavaScript for the Purdue Zipcode Integration. Meets requirement 3.
 * Allows users to create Location Identifiers using ZIP codes.
 * @extends LightningElement
 */
export default class ZIpIntegrationLWC_EnterZip extends LightningElement {
    @wire(IsConsoleNavigation) isConsoleNavigation; // Determines if user is in a console app
    @track showLoadingSpinner = false; // Controls the loading spinner visibility
    @track zipCode; // Holds the ZIP code entered by the user
    @api recordId; // Record ID passed from the parent component; used to update record if on record page.
    savedRecId; // Holds the saved Location Identifier record ID

    /**
     * Handles changes in the input field and updates the zipCode property.
     * @param {Event} event - The input change event.
     */
    setZip(event) {
        this.zipCode = event.detail.value;
    }

    /**
     * Validates the input fields and returns true if they are all valid.
     * If false, will not invoke LWC Handler class.
     * @returns {boolean} - True if input is valid; otherwise, false.
     */
    isInputValid() {
        let isValid = true;
        let inputFields = this.template.querySelectorAll("lightning-input");
        inputFields.forEach((inputField) => {
            if (!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
        });

        return isValid;
    }

    /**
     * Initiates the process of creating a Location Identifier record based on the entered ZIP code.
     * Displays success or error messages and handles tab refreshing if applicable.
     * @param {Event} event - The click event.
     */
    createData(event) {
        if (this.isInputValid()) {
            this.showLoadingSpinner = true;
            createLocationIdentifiers({
                zipCode: this.zipCode,
                recordId: this.recordId
            })
                .then((result) => {
                    this.savedRecId = result;
                    console.log(
                        JSON.stringify("Apex create result: " + result)
                    );
                    if (this.isConsoleNavigation) {
                        getFocusedTabInfo()
                            .then((tabInfo) => {
                                refreshTab(tabInfo.tabId);
                            })
                            .catch((error) => {
                                console.log(error);
                            });
                    }
                    this.showLoadingSpinner = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Successfully created Location Identifier record.",
                            message:
                                "Great success! Record Id: " + this.savedRecId,
                            variant: "success"
                        })
                    );
                })
                .catch((error) => {
                    window.console.log("ERROR ====> " + error);
                    this.showLoadingSpinner = false;
                    this.savedRecId = "";
                    this.dispatchEvent(new RefreshEvent());
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "An error has occurred.",
                            message: error.body.message,
                            variant: "error"
                        })
                    );
                });
        } else {
            this.savedRecId = "";
            this.dispatchEvent(new RefreshEvent());
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Input is invalid",
                    message: "Please try again. Zip codes should be 5 digits.",
                    variant: "Informational"
                })
            );
        }
    }













    
    /*

    createData() {
        if (this.isInputValid()) {
            this.showLoadingSpinner = true;
            const fields = { Zip_Code__c: this.zipCode };
            const recordInput = { apiName: "Location_Identifier__c", fields };

            createRecord(recordInput)
                .then((response) => {
                    this.savedRecId = response.id;
                    this.message = "Location Identifier Created";
                    this.showLoadingSpinner = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Successfully created Location Identifier record.",
                            message: "Great success! Record Id: " + this.savedRecId,
                            variant: "success"
                        })
                    );
                })
                .catch((error) => {
                    this.message = "Error creating Location Identifier";
                    this.showLoadingSpinner = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "An error has occurred.",
                            message: JSON.stringify(error),
                            variant: "error"
                        })
                    );
                });
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Input is invalid",
                    message: "Please try again",
                    variant: "Informational"
                })
            );
            
        }
    }
    */
}
