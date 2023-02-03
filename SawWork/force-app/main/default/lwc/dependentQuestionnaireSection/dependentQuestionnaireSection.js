/**
*  @Date		:	April 15 2021
*  @Author		: 	Shivam Verma
*  @Description	:	Component for handling dependent questions
*/
import { track, api, LightningElement } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import getDependentQuestions from '@salesforce/apex/QuestionnaireController.getDependentQuestionsForParent';
import getDependentQuestionsForParentInChimeForm from '@salesforce/apex/QuestionnaireController.getDependentQuestionsForParentInChimeForm';

import getQuestionsById from '@salesforce/apex/QuestionnaireController.getQuestionsById';

import QUESTION from '@salesforce/schema/CHIME_Product_Question__c';
import QUESTION_PRODUCT from '@salesforce/schema/CHIME_Product_Question__c.CHIME_Product__c';
import QUESTION_PARENT from '@salesforce/schema/CHIME_Product_Question__c.Parent_Question__c';
import QUESTION_TYPE from '@salesforce/schema/CHIME_Product_Question__c.Question_Type__c';
import QUESTION_EXPECTION_RESPONSE from '@salesforce/schema/CHIME_Product_Question__c.Expected_Response__c';
import QUESTION_SECTION from '@salesforce/schema/CHIME_Product_Question__c.Section__c';
import QUESTION_SERIAL_NUMBER from '@salesforce/schema/CHIME_Product_Question__c.Serial_Number__c';
import QUESTION_SECTION_SERIAL_NUMBER from '@salesforce/schema/CHIME_Product_Question__c.Section_Serial_Number__c';
import QUESTION_DEPENDENT_SERIAL from '@salesforce/schema/CHIME_Product_Question__c.Dependent_Question_Serial__c';
import FORM_STAGE from '@salesforce/schema/CHIME_Product_Question__c.Form_Stage__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import adminTemplate from './dependentQuestionnaireSection.html';
import previewTemplate from './dependentQuestionnaireChimeSection.html';

export default class DependentQuestionnaireSection extends LightningElement {

    timelineOpenClasses     = "slds-timeline__item_expandable slds-timeline__item_task slds-is-open";
    timelineCloseClasses    = "slds-timeline__item_expandable slds-timeline__item_task slds-is-close";
    showDependent = false;

    @track dependentQuestions = [];
    @track dependentQuestionsWithPreviewAttribute = [];
    @track createdQuestion;
    @track showQuestionTypeSelection = false;
    @track showEditQuestion = false;
    @track createQuestionType;
    @track questionTypeClasses;
    @track questionCreationClasses;

    questionCompleted = false;
    questionInprogress = false;
    notActive = true;

    @api productid;
    @api optionval;
    @api chimeid;
    @api fromadmin;
    //@api parentquestionid;
    @api parentquestion;
    @api chimeformmode;
    @api showalldependent;

    previewmode = true;
    showPreview = true;

    timelineOpenClasses     = "slds-timeline__item_expandable slds-timeline__item_task slds-is-open";
    timelineCloseClasses    = "slds-timeline__item_expandable slds-timeline__item_task slds-is-close";


    @api showdependentpreview =false;
    connectedCallback() {

        this.questionTypeClasses   = this.timelineCloseClasses;
        this.questionCreationClasses = this.timelineCloseClasses;
        this.getDependentQuestionsList();
    }

    render() {
        console.log("Is chime form mode ?");
        console.log(this.chimeformmode);
        //this.chimeformmode = false;
        return this.chimeformmode ? previewTemplate : adminTemplate;
    }

    handleNewDependentClick() {
        this.getDependentQuestionsList();
        this.showEditQuestion = false;
        this.createdQuestion = [];
        this.showQuestionTypeSelection = true;
    }

    @api
    handleProductChangeForDependents() {
        this.getDependentQuestionsList();
    }

    getDependentQuestionsList() {
        let dependentQuestionsWithPreviewAttributeList = [];
        console.log("Get dependent questions");
        console.log("parentquestion :"+this.parentquestion.Id);
        console.log("expectionResponse :"+this.optionval);
        if(this.chimeformmode){
            //when Chime form is loaded, load questions based on the Chime form Id and tempplate.
            getDependentQuestionsForParentInChimeForm ( {parentQuestionId: this.parentquestion.Id, expectionResponse: this.optionval, productId: this.productid, chimeId : this.chimeid})
            .then (result => {
                console.log("Got result");
                console.log(result);
                for(let key in result){
                    let ques = result[key];
                    if (this.showalldependent) {
                        ques.TruncatedPreview = true;
                    }
                    dependentQuestionsWithPreviewAttributeList.push(ques);
                }
                /*if(result.length==0){
                    this.dispatchEvent(new CustomEvent('removedependentquestion', { 
                        bubbles: true, 
                        composed: true,
                        detail : JSON.parse(JSON.stringify(this.dependentQuestions)) 
                    }));
                }*/
                this.dependentQuestions = result;
                console.log(dependentQuestionsWithPreviewAttributeList);
                this.dependentQuestionsWithPreviewAttribute = dependentQuestionsWithPreviewAttributeList;

                this.dispatchEvent(new CustomEvent('adddependentquestion', { 
                    bubbles: true, 
                    composed: true,
                    detail : JSON.parse(JSON.stringify(result)) 
                }));
                
            })
            .catch( error => {
                console.log("Error getting questions");
                console.log(error);
            });
        }else{        
            getDependentQuestions ( {parentQuestionId: this.parentquestion.Id, expectionResponse: this.optionval, productId: this.productid})
            .then (result => {
                console.log("Got result");
                console.log(result);
                for(let key in result){
                    let ques = result[key];
                    if (this.showalldependent) {
                        ques.TruncatedPreview = true;
                    }
                    dependentQuestionsWithPreviewAttributeList.push(ques);
                }
                this.dependentQuestions = result;
                console.log(dependentQuestionsWithPreviewAttributeList);
                this.dependentQuestionsWithPreviewAttribute = dependentQuestionsWithPreviewAttributeList;
            })
            .catch( error => {
                console.log("Error getting questions");
                console.log(error);
            });
        }
    }

    handleQuestionTypeClick(event) {
        this.questionTypeSelected      = event.target.label;
        this.createQuestionType        =  event.target.label;
        console.log('create question type :'+this.createQuestionType);
        //this.questionTimelineClasses   = this.timelineCloseClasses;
        //this.setionTimelineClasses     = this.timelineOpenClasses;
        this.showQuestionTypeSelection = false;
        this.createNewQuestion();
    }

    showCompletePreview(event) {
        let questionId = event.currentTarget.id;
        console.log("Complete preview :"+questionId);
        if (questionId.indexOf('-') > -1) {
            questionId = questionId.split("-")[0];
        }
        console.log(questionId);

        let updatedQuestions = [];
        for(let key in this.dependentQuestions){
            let ques = this.dependentQuestions[key];
            if (ques.Id == questionId) {
                ques.TruncatedPreview = !ques.TruncatedPreview;
                updatedQuestions.push(ques);
            } else {
                updatedQuestions.push(ques);
            }
            this.dependentQuestionsWithPreviewAttribute = updatedQuestions;
        }

    }
    
    createNewQuestion() {

        //console.log("Creating new dependent question : "+this.section);
        console.log("Type : "+this.createQuestionType);
        console.log("Parent question :");
        console.log(this.parentquestion);

        let questionTypeValue;
        if (this.createQuestionType === "Text Type") {
            questionTypeValue = 'Text';
        } else {
            questionTypeValue = 'Picklist';
        }

        //Get the Serial number from existing questions
        let lastQuestion;
        if (this.dependentQuestions !== undefined && this.dependentQuestions.length > 0) {
            lastQuestion = this.dependentQuestions[this.dependentQuestions.length - 1];
        }
        console.log("lastQuestion");
        console.log(lastQuestion);
        
        const fields = {};
        fields[QUESTION_TYPE.fieldApiName] = questionTypeValue;
        fields[QUESTION_PRODUCT.fieldApiName] = this.productid;
        fields[QUESTION_EXPECTION_RESPONSE.fieldApiName] = this.optionval;
        //Set the paerent id
        fields[QUESTION_PARENT.fieldApiName] = this.parentquestion.Id;
        fields[FORM_STAGE.fieldApiName] = this.parentquestion.Form_Stage__c;
        
        if (lastQuestion === undefined) {
            fields[QUESTION_SECTION.fieldApiName] = this.parentquestion.Section__c;
            fields[QUESTION_SERIAL_NUMBER.fieldApiName] = this.parentquestion.Serial_Number__c;
            fields[QUESTION_DEPENDENT_SERIAL.fieldApiName] = 1;
            fields[QUESTION_SECTION_SERIAL_NUMBER.fieldApiName] = this.parentquestion.Section_Serial_Number__c;
        } else {
            fields[QUESTION_SECTION.fieldApiName] = lastQuestion.Section__c;
            fields[QUESTION_SERIAL_NUMBER.fieldApiName] = lastQuestion.Serial_Number__c;
            fields[QUESTION_DEPENDENT_SERIAL.fieldApiName] = lastQuestion.Dependent_Question_Serial__c + 1;
            fields[QUESTION_SECTION_SERIAL_NUMBER.fieldApiName] = lastQuestion.Section_Serial_Number__c;
        }
        console.log("fields")
        console.log(fields);
        const recordInput = { apiName: QUESTION.objectApiName, fields };

        console.log("Creating record");

        //create question record
        createRecord(recordInput)
            .then(result => {
                console.log("Dependent question created successfully");
                console.log(result);
                this.createdQuestionId = result.id;
                return result.id;
            })
            .then( (questionid) => {
                getQuestionsById( {questionId: questionid}) 
                    .then( quesResult => {
                        console.log("System send back created question");
                        console.log(quesResult);
                        if (quesResult.length > 0) {
                            this.createdQuestion = quesResult[0];
                            this.showEditQuestion = true;
                        }
                    })
                    .catch( error => {
                        console.log("Error refreshing section");
                        console.log(error);
                    });
                }
            )
            .catch(error => {
                console.log("Error creating dependent question");
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating Question. Please contact administrator',
                        message: error.body.message,
                        message: "Error outer",
                        variant: 'error',
                    }),
                );
            });

    }
}