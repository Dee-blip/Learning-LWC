import BasePrechat from 'lightningsnapin/basePrechat';
import { api, track } from 'lwc';
import chatTexts from '@salesforce/label/c.Mkt_EC_Text';
import chatTexts1 from '@salesforce/label/c.Mkt_EC_Text1';

export default class Prechat extends BasePrechat {
    @api prechatFields;
    @api backgroundImgURL;
    @track fields;
  
    @track namelist;
    @track support = false;
    @track chat = false;
    @track displayPhone = false;
    @track geoContactText = null;
    @track geoContextLink = null;
    @track chatText = JSON.parse(chatTexts);
    @track chatText1 = JSON.parse(chatTexts1);
    /**
     * Set the button label and prepare the prechat fields to be shown in the form.
     */
     connectedCallback() {
        if(document.querySelector('body') != null) {
            this.geoContactText = document.querySelector('body').getAttribute("geo-contacttext");
            this.geoContextLink = document.querySelector('body').getAttribute("geo-contactlink");
            if(this.geoContactText != null && this.geoContextLink != null){
                this.displayPhone = true;
            }
        }  
        this.fields = this.prechatFields.map(field => {
            field = JSON.parse(JSON.stringify(field))
            field.className = "input-field";
            field.textArea = false;
            field.isMessageField = false;
            if(field.type.split('input').length > 1) {
                field.type =  field.type.split('input')[1];    
            }
            if(field.name.includes('Name')) { 
                field.className = "left";
                field.required = false;
            }
            if(field.maxLength === 255 && field.name !== 'Company') { 
                field.isMessageField = true;
            }
            if(field.name === 'Company') {
                field.className = "clear input-field";
            }
            let { label, name, value, type, required, maxLength, className, textArea, isMessageField } = field;
            return { label, value, name, type, required, maxLength, className, textArea, isMessageField };
        });
        this.namelist = this.fields.map(field => field.name);
    }

    /**
     * Focus on the first input after this component renders.
     */
    renderedCallback() {
        //this.template.querySelector("lightning-input").focus();
    }

    /**
     * On clicking the 'Start Chatting' button, send a chat request.
     */
    initiateChat() {
        this.createCustomEvent('clickOnChatWithSalesAgent');
        this.startChat(this.fields);
    }

    handleSupport() {
        this.chat = false;
        this.support = true;
        this.createCustomEvent('clickonSupport');
    }

    handleChat() {
        this.chat = true;
        this.support = false;
    }


    handleRedirection(){
        this.createCustomEvent('clickOnMoreContactOptions');
        window.open(this.chatText1.contactUrl);
        }

    communityEvent(){
        this.createCustomEvent('clickOnCommunityLink');
    }

    mailEvent(){
        this.createCustomEvent('clickOnSupportMail');
    }

    createCustomEvent(eventName){
        var event = new CustomEvent(eventName);
        document.dispatchEvent(event);
    }

    // handleCountryChange(event){
    //     console.log(event);
    //     console.log(event.target.value);
    //     this.fields[this.namelist.indexOf("Person_Country__c")].value = event.target.value;
    //     this.preChatDetails=[];
    //     this.preChatDetails.push(`"Country":"${event.target.value}"`); 
    //     if((this.fields[this.namelist.indexOf('Person_Country__c')].value === "")){
    //         this.countryreq = true;
    //     }else{
    //         this.countryreq = false;
    //     }
        
    // }
}