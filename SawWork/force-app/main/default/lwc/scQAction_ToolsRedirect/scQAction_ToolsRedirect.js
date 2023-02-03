/*=====================================================================================================+
    Component name      :   scQAction_AutoCloseCase
    Author              :   Jay Rathod
    Created             :   25-Aug-2021
    Purpose             :   Created to click/open Tools button present in SC_PS_PageLayout_Buttons aura component

    Last Modified Developer                     Purpose
    ============= ========================      =======
    25-Aug-2021   Jay Rathod                    ESESP-5716: Initial Development
+=====================================================================================================*/
import {LightningElement,api} from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import getToolUrl from "@salesforce/apex/SC_Case_LightningUtility.getToolUrl";
import {ShowToastEvent} from "lightning/platformShowToastEvent";

export default class ScQActionToolsRedirect extends LightningElement {

    @api
    recordId;

    @api
    async invoke(){
        try{
            let toolUrl = await getToolUrl({caseId: this.recordId});
            window.open(toolUrl,'_blank');
            this.closeQuickAction();
        }catch (e) {
            console.error(e);
            this.dispatchEvent(new ShowToastEvent({
                message: e.message || (e.body && e.body.message) || 'Something went wrong!',
                variant: "error"
            }))
        }
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

}