/**
*  @Date		:	Feb 2021
*  @Author		: 	Shivam Verma
*  @Description	:	Top component in the Chime Admin Questionanaire, hold multiple sections and toolkit component
*/
import { api, track, wire, LightningElement } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import noheader from '@salesforce/resourceUrl/noheader';
import getQuestions from '@salesforce/apex/QuestionnaireController.getQuestions';
import getQuestionsForAdmin from '@salesforce/apex/QuestionnaireController.getQuestionsForAdmin';
import EMPTY_CONTAINER from '@salesforce/messageChannel/L2Q_ChimeEmptyContainerNotification__c';
import { publish, MessageContext } from 'lightning/messageService';
//import getProductData from '@salesforce/apex/QuestionnaireController.getProductData';

export default class QuestioannaireComponent extends LightningElement {
    @wire(MessageContext) messageContext;
    @api productid;
    @api stage;
    @api chimeid;

    @api fromadmin=false;

    @track previewmode = false;
    @api get previewmode() {
        return this.previewmode;
    }
    set previewmode(value) {
        this.previewmode = value;
    }

    @track sections=[];
    @track mapSectionKeyToQuestions=[];

    @track addQuestion=false;
    @track selectQuestionSection=false;

    //attributes for tracking timelines
    @track questionTypeText = "Select Question Type";
    @track questionTimelineClasses;
    @track questionTypeSelected;
    @track sectionNameText = "Select Section";
    @track setionTimelineClasses;
    @track sectionTypeSelected;
    @track actionTypeText = "Confirm Selection";
    @track actionTimelineClasses;
    @track showIllustration;

    timelineOpenClasses = "slds-timeline__item_expandable slds-timeline__item_task slds-is-open";
    timelineCloseClasses = "slds-timeline__item_expandable slds-timeline__item_task slds-is-close";

    //P1 changes
    @api chimeStage;
    @api chimeStatus;
    @api responseDisable;

    //CHIME P2 change
    @api ispoc=false;

    connectedCallback() {
        loadStyle(this, noheader);
        //console.log("Product id in conected callback :"+this.productid);
        //console.log("Stage id in conected callback :"+this.stage);

        if (this.productid === undefined) {
            const productIdValue = this.getUrlParamValue(window.location.href, 'c__productid');
            this.productid = productIdValue;
            //console.log("Product id after setting from url :"+this.productid);
        }

        if (this.getUrlParamValue(window.location.href, 'c__fromadmin')) {
            this.fromadmin = this.getUrlParamValue(window.location.href, 'c__fromadmin');
            //console.log("Question section :"+this.fromadmin);
        }
        //load product questions
        let firstLoad = true;
        this.loadProductQuestions(firstLoad);

    }

    renderedCallback(){
        //console.log('in rendered callback of question comp'+this.showIllustration+'map:'+JSON.stringify(this.mapSectionKeyToQuestions));
        if(this.showIllustration)
        {
            const message = {
                publish: true,
                source: 'questionnaireComponent',
                isEmpty: true
            };
            publish(this.messageContext, EMPTY_CONTAINER, message);

        }
    }

    handleAddQuestion() {
        this.addQuestion = !this.addQuestion;
        this.questionTimelineClasses = this.timelineOpenClasses;
        this.setionTimelineClasses = this.actionTimelineClasses = this.timelineCloseClasses;
    }

    handleQuestionTypeClick(event) {
        this.questionTypeSelected = event.target.label;
        this.questionTypeText = event.target.label;
        this.questionTimelineClasses = this.timelineCloseClasses;
        this.setionTimelineClasses = this.timelineOpenClasses;
    }

    handleSectionClick(event) {
        this.sectionNameText = event.target.label;
        this.setionTimelineClasses = this.timelineCloseClasses;
        this.actionTimelineClasses = this.timelineOpenClasses;
    }

    handleQuestionCreation(event) {
            let target = this.template.querySelector(`[data-id="${event.detail.section}"]`);
            target.createNewQuestion(event.detail.type, event.detail.section, event.detail.sectionSerial);
    }

    handleSectionCreation(event) {
        this.showIllustration = false;
        let sectionName = event.detail.newSectionName;
        this.mapSectionKeyToQuestions.push({key:sectionName,value:[]});
    }

    handleProductSelect(productid) {
        //console.log("Inside question component. Product id -"+productid);
        this.productid = productid;
    }
    @api
    handleStageChange(){
        //console.log('Inside QuestionnaieComponent');
        //code to call method to show reloaded responses on stage change
        let questionnaireSecComp = this.template.querySelector('.questionSectionComponent');
        if (questionnaireSecComp) {
            questionnaireSecComp.handleStageChange();
        }
    }

    @api
    handleProductChange(value,stage,chimeid) {
        this.productid = value;
        this.stage = stage;
        this.chimeid = chimeid;
        //console.log("Product changed - Load for stage : "+stage);
        let firstLoad = false;
        this.loadProductQuestions(firstLoad);
    }

    loadProductQuestions(firstLoad) {
        if(this.fromadmin === false){
            //console.log("loading questions for stage "+this.stage);
            getQuestions ( {productId: this.productid, stage: this.stage, chimeid : this.chimeid, isPOC : this.ispoc})
            .then (result => {
                let resultObj = JSON.parse(JSON.stringify(result));
                //console.log("product change questons list ::: ",result);

                if (Object.keys(resultObj).length === 0 && resultObj.constructor === Object) {
                    this.showIllustration = true;
                } else {
                    //empty the existing sections
                    this.mapSectionKeyToQuestions = [];
                    //Populate the updated product questions
                    for(let key in resultObj){
                        this.mapSectionKeyToQuestions.push({key:key,value:result[key]});
                        this.sections.push(key);
                    }
                    this.showIllustration = false;
                }
            }).then( () => {
                if (!firstLoad) {
                    //console.log("Questionnaire Component update sections");
                    this.template.querySelectorAll('.questionSectionComponent').forEach(section => {
                    section.updateSectionAfterProductChange();
                    });
                }
            })
            .catch( error => {
                console.log("Error getting questions");
                console.log(error);
            });
        }else{
            getQuestionsForAdmin ( {productId: this.productid})
            .then (result => {
                let resultObj = JSON.parse(JSON.stringify(result));
                if (Object.keys(resultObj).length === 0 && resultObj.constructor === Object) {
                    this.showIllustration = true;
                } else {
                    for(let key in resultObj){
                        this.mapSectionKeyToQuestions.push({key:key,value:result[key]});
                        this.sections.push(key);
                    }
                    this.showIllustration = false;
                }
            })
            .catch( error => {
                //console.log("Error getting questions");
                //console.log(error);
            });
        }
    }

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    @api
    fetchQuestionIds(){
        let quesIds=[];
        this.template.querySelectorAll('.questionSectionComponent').forEach(section =>{
            let sectionQuesIds = section.fetchQuestionIds();
            //console.log('sectionQuesIds',sectionQuesIds);
            quesIds = quesIds.concat(sectionQuesIds);
        })
        //console.log('quesIds',quesIds);
        return quesIds;
    }
}