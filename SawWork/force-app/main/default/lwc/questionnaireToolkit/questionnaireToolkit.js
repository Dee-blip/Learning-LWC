/**
*  @Date		:	April 15 2021
*  @Author		: 	Shivam Verma
*  @Description	:	Toolkit component for Question operation.
*                   Component supports -
*                   - Action for Publish questionnaire 
*                   - Action to create sections
*                   - Action to create different types of questions
*/
import { track,api,wire, LightningElement } from 'lwc';
import { publish, subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import publishQuestionnaireNotify from '@salesforce/apex/QuestionnaireController.publishQuestionnaireNotify';
import QUESTIONNAIRE_PUBLISH_MESSAGE from '@salesforce/messageChannel/l2q_QuestionnairePublish__c';
import PREVIEW_PUBLISH from '@salesforce/messageChannel/l2q_PreviewBeforePublish__c';
import EMPTY_CONTAINER from '@salesforce/messageChannel/L2Q_ChimeEmptyContainerNotification__c';
import createTemplate from '@salesforce/apex/QuestionnaireController.createTemplate';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import Available_FOR_CHIME from '@salesforce/schema/PAC_Product_Catalog__c.Is_Available_For_Chime__c';
import PRODUCT_ID from '@salesforce/schema/PAC_Product_Catalog__c.Id';
import { reduceErrors } from 'c/l2QlwcUtil';

export default class QuestionnaireToolkit extends LightningElement {

    //Changes by Manish for Questionnaire Refresh
    @api productid;
    showNotes= false;
    notesvalue='';
    templateid;

    @track mapSectionkeyToSectionName   =[];
    @track sections     =[];
    @api get sections() {
        return this.sections;
    }
    set sections(value) {
        this.sections = value;
    }

    @wire(MessageContext) messageContext;

    @track addQuestion              =false;
    @track addSection               =false;
    @track selectQuestionSection    =false;
    @track newSectionInput;

    /* Timeline classes*/
    @track questionTypeText         = "Select Question Type";
    @track sectionNameText          = "Select Section";
    @track actionTypeText           = "Confirm Selection";
    @track questionTimelineClasses;
    @track questionTypeSelected;
    @track setionTimelineClasses;
    @track sectionTypeSelected;
    @track actionTimelineClasses;
    noQuestionsExist=true;
    nonEmptySections =[];
    subscription = null;

    sectionName1            = "Section : General Information";
    sectionName2            = "Section : Marketing Information";
    timelineOpenClasses     = "slds-timeline__item_expandable slds-timeline__item_task slds-is-open";
    timelineCloseClasses    = "slds-timeline__item_expandable slds-timeline__item_task slds-is-close";

    connectedCallback(){
        this.subscription = subscribe(
            this.messageContext,
            EMPTY_CONTAINER,
            (message) => {
                this.handleEmptyContainerNotification(message);
            });
    }
    disconnectedCallback() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    handleEmptyContainerNotification(message){
        if(message.source=='questionnaireComponent' && message.isEmpty){
            this.noQuestionsExist=true;
        }
        else if(message.source=='questionnaireSectionComponent'){
            if(message.isEmpty)
            {
                if(this.nonEmptySections.indexOf(message.sourceId)>-1)
                    this.nonEmptySections.splice(this.nonEmptySections.indexOf(message.sourceId));
            }
            else
            {
                if((this.nonEmptySections.indexOf(message.sourceId)==-1))
                    this.nonEmptySections.push(message.sourceId);
            }
            this.noQuestionsExist=(this.nonEmptySections.length == 0);
        }
    }

    handleAddQuestion() {
        this.addQuestion                = !this.addQuestion;
        this.addSection                 = false;
        this.questionTimelineClasses    = this.timelineOpenClasses;
        this.setionTimelineClasses      = this.actionTimelineClasses = this.timelineCloseClasses;
    }

    handleQuestionTypeClick(event) {
        this.questionTypeSelected      = event.target.label;
        this.questionTypeText          =  "Type :" + event.target.label;
        this.questionTimelineClasses   = this.timelineCloseClasses;
        this.setionTimelineClasses     = this.timelineOpenClasses;
    }

    handleQuestionTypeReopen() {
        this.questionTimelineClasses    = this.timelineOpenClasses;
        this.setionTimelineClasses      = this.timelineCloseClasses;
        this.actionTimelineClasses      = this.timelineCloseClasses;
    }

    handleSectionClick(event) {
        this.sectionNameText            = event.target.label;
        this.setionTimelineClasses      = this.timelineCloseClasses;
        this.actionTimelineClasses      = this.timelineOpenClasses;
    }

    handleSectionReopen() {
        this.questionTimelineClasses    = this.timelineCloseClasses;
        this.setionTimelineClasses      = this.timelineOpenClasses;
        this.actionTimelineClasses      = this.timelineCloseClasses;
    }

    handleAddSection() {
        this.addSection = !this.addSection;
        this.addQuestion = false;
        this.questionTimelineClasses = this.timelineOpenClasses;
        this.setionTimelineClasses = this.actionTimelineClasses = this.timelineCloseClasses;
    }

    handleSectionInput(event) {
        this.newSectionValue = this.event.target.value;
    }

    handleQuestionCreation() {
        let sectionSerial = this.sections.indexOf(this.sectionNameText);
        sectionSerial = sectionSerial == 0? 1: (sectionSerial+1);
        let createQuestionObject = { type: this.questionTypeSelected, section: this.sectionNameText, sectionSerial:sectionSerial };
        // Creates the event with the question type and section name data.
        this.dispatchEvent(new CustomEvent('createquestion', { detail: createQuestionObject }));
        this.addQuestion = false;
        this.questionTypeText = "Select Question Type";
        this.sectionNameText = "Select Section";
    }

    handleCreationCancel() {
        this.addQuestion = false;
        this.questionTypeText = "Select Question Type";
        this.sectionNameText = "Select Section";
    }

    handleNewSectionInput(event) {
        this.newSectionInput = event.target.value;
    }

    handleSectionCreation() {
        // Creates the event with the question type and section name data.
        let sectionObj = [];
        if (Object.keys(this.sections).length !== 0 && this.sections.constructor !== Object) {
            sectionObj = JSON.parse(JSON.stringify(this.sections));
        }
        let sectionNumber = sectionObj.push(this.newSectionInput) + 1;
        this.sections = sectionObj;
        let createQuestionObject = { newSectionName: this.newSectionInput, sectionNumber: sectionNumber };
        this.dispatchEvent(
                new CustomEvent('createsection',
                                    {bubbles: true, 
                                    composed: true, 
                                    detail :createQuestionObject}
                                )
                );
        this.addSection=false;
    }

    handleSectionCancel() {
        this.addSection = false;
    }

    /*
     * Fire event to publish all the questions
    */
    handlePublish() {
        if(this.noQuestionsExist){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please add questions before publishing',
                    variant: 'error'
                })
            );
            return;
        }
        if(this.notesvalue== null || this.notesvalue == ''){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Info',
                    message: 'Please fill the Publisher Notes!',
                    variant: 'info'
                })
            );
        }
        else{
            createTemplate({ productId : this.productid})
            .then(result => {
                this.templateid = result;

                const message = {
                    publish: true,
                    templateid :this.templateid,
                    productid : this.productid
                };
                publish(this.messageContext, QUESTIONNAIRE_PUBLISH_MESSAGE, message);
                publishQuestionnaireNotify({ productId : this.productid , notes : this.notesvalue , templateId : this.templateid})
                .then(result => {
                    console.log(result);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Questionnaire has been published.',
                            variant: 'success'
                        })
                    )
                })
                .catch(error => {
                    console.log('error',error);
                });
                this.showNotes= false;

                const fields = {};
                fields[PRODUCT_ID.fieldApiName] = this.productid;
                fields[Available_FOR_CHIME.fieldApiName] = true;
                const recordInput = { fields };
                updateRecord(recordInput);
                setTimeout(this.handleCancel('toast'),2000);
            })
            .catch(error => {
                console.log('Error while creating template.'+JSON.stringify(error));
                console.log('Error while creating template1.'+reduceErrors(error));
            });
        }
    }

    handleNotesChange(event){
        this.notesvalue= event.detail.value;
    }
    handlePublishClick(){
        if(this.showNotes == false){
        const message = {
            preview: true
        };
        publish(this.messageContext, PREVIEW_PUBLISH, message);
    }
        this.showNotes= !this.showNotes;
    }
    handleCancel(check){
        const message = {
            preview: false
        };
        publish(this.messageContext, PREVIEW_PUBLISH, message);
        this.showNotes= false;
        this.notesvalue='';
        if(check=='toast'){
            //setTimeout(,1000);
        }
    }
}