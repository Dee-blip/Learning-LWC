/*=====================================================================================================+
    Component name      :   scQAction_AutoCloseCase
    Author              :   Jay Rathod
    Created             :   25-Aug-2021
    Purpose             :   Created to click/open Invalid button present in SC_PS_PageLayout_Buttons aura component

    Last Modified Developer                     Purpose
    ============= ========================      =======
    25-Aug-2021   Jay Rathod                    ESESP-5716: Initial Development
+=====================================================================================================*/
import {LightningElement, api, wire} from 'lwc';
import {MessageContext} from "lightning/messageService";
import openCustomButton from "c/scOpenCustomButtons";

export default class ScQActionCloseInvalidCase extends LightningElement {

    @wire(MessageContext)
    messageContext;

    @api
    async invoke(){
        openCustomButton(this.messageContext,"MarkCaseAsInvalid");
    }

}