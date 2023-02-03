/**
*  @Date		:	Feb 2021
*  @Author		: 	Shivam Verma
*  @Description	:	Component to hold sections in Chime Admin Questionanaire -
*                   Supports - Creation of a new question in section
*                              Deletion of question
*                              Move up and move down for questions
*/
import { api, wire, track, LightningElement } from 'lwc';
import { createRecord  } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import QUESTION from '@salesforce/schema/CHIME_Product_Question__c';
import QUESTION_PRODUCT from '@salesforce/schema/CHIME_Product_Question__c.CHIME_Product__c';
import QUESTION_TYPE from '@salesforce/schema/CHIME_Product_Question__c.Question_Type__c';
import QUESTION_STAGE from '@salesforce/schema/CHIME_Product_Question__c.Form_Stage__c';
import QUESTION_SECTION from '@salesforce/schema/CHIME_Product_Question__c.Section__c';
import QUESTION_SERIAL_NUMBER from '@salesforce/schema/CHIME_Product_Question__c.Serial_Number__c';
import QUESTION_SECTION_SERIAL_NUMBER from '@salesforce/schema/CHIME_Product_Question__c.Section_Serial_Number__c';
import getQuestionsForSection from '@salesforce/apex/QuestionnaireController.getQuestionsForSection';
import updateSectionAfterDelete from '@salesforce/apex/QuestionnaireController.updateSectionAfterDelete';
import { publish, MessageContext } from 'lightning/messageService';
import EMPTY_CONTAINER from '@salesforce/messageChannel/L2Q_ChimeEmptyContainerNotification__c';

export default class QuestionnaireSectionComponent extends LightningElement {
    @wire(MessageContext) messageContext;
    @api section;
    @api productid;
    @api stage;
    @api chimeid;
    @api previewmode;
    @api fromadmin;
    @track sectionClasses = "slds-section slds-is-open";
    @track expanded = true;

    @track questionType;
    @track showIllustration=false;

    @track questions=[];

    @api get questions() {
        return this.questions;
    }
    set questions(values) {
        this.questions = values;
    }

    createdQuestionId;

    //P1 changes
    @api chimeStage;
    @api chimeStatus;
    @api responseDisable;

    connectedCallback() {
        let questionsString = JSON.stringify(this.questions);
        this.questions = JSON.parse(questionsString);
        if (this.questions.length == 0) {
            this.showIllustration=true;
        }
    }

    renderedCallback(){
        console.log('in renderedcallback of questionnairesection'+this.showIllustration+'in '+this.section);
       
        const message = {
                publish: true,
                source: 'questionnaireSectionComponent',
                isEmpty: this.showIllustration,
                sourceId: this.section
            };
            publish(this.messageContext, EMPTY_CONTAINER, message);
    }

    handleSectionClick() {
        this.expanded = !this.expanded;
        if (this.expanded) {
            this.sectionClasses = "slds-section slds-is-close";
        } else {
            this.sectionClasses = "slds-section slds-is-open";
        }
    }

    @api
    createNewQuestion(type, section, sectionSerial) {

        let questionTypeValue;
        if (type === "Text Type") {
            questionTypeValue = 'Text';
        } else {
            questionTypeValue = 'Picklist';
        }

        let lastQuestion;
        //Get the Serial number from existing questions
        console.log('printing length'+this.questions.length);
        for (const qi of this.questions){
            if(!(qi.isDeletedFromUI === true))
            {
                lastQuestion = qi;
            }
                
        }
        
        const fields = {};
        fields[QUESTION_TYPE.fieldApiName] = questionTypeValue;
        fields[QUESTION_PRODUCT.fieldApiName] = this.productid;
        fields[QUESTION_STAGE.fieldApiName] = "Gating";
        if (lastQuestion == undefined) {
            fields[QUESTION_SECTION.fieldApiName] = section;
            fields[QUESTION_SERIAL_NUMBER.fieldApiName] = 1;
            fields[QUESTION_SECTION_SERIAL_NUMBER.fieldApiName] = sectionSerial;
        } else {
            fields[QUESTION_SECTION.fieldApiName] = lastQuestion.Section__c;
            fields[QUESTION_SERIAL_NUMBER.fieldApiName] = lastQuestion.Serial_Number__c + 1;
            fields[QUESTION_SECTION_SERIAL_NUMBER.fieldApiName] = lastQuestion.Section_Serial_Number__c;
        }

        const recordInput = { apiName: QUESTION.objectApiName, fields };

        //create question record
        createRecord(recordInput)
            .then(result => {
                this.createdQuestionId = result.id;
            })
            .then( () => {
                getQuestionsForSection( {sectionName: section, productId: this.productid}) 
                    .then( quesResult => {
                        this.questions = quesResult;
                        this.showIllustration = false;
                    })
                    .catch( error => {
                        console.log("Error refreshing section");
                        console.log(error);
                    });
                }
            )
            .catch(error => {
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

    updateSection() {
        getQuestionsForSection( {sectionName: this.section, productId: this.productid}) 
        .then( quesResult => {
            this.questions = JSON.parse(JSON.stringify(quesResult));
            this.showIllustration = false;
        })
        .catch( error => {
            console.log("Error refreshing section");
            console.log(error);
        });
    }

    updateSectionQuestions() {
        console.log('calling apex');
        updateSectionAfterDelete( {sectionName: this.section, productId: this.productid}) 
        .then( quesResult => {
            if (Object.keys(quesResult).length === 0 && quesResult.constructor === Object) {
                this.showIllustration = true;
            } else {
                this.questions = quesResult;
            }
        })
        .catch( error => {
            console.log("Error refreshing section");
            console.log(error);
        });
    }

    handlePublish() {
        this.template.querySelectorAll('c-multiple-choice-question-edit-component').forEach(question => {
            question.handlePublish();
        });
    }
    //method to delete the ques from the section and set the serial of question.
    updateAfterDeleteQues(event){ 
        var quesList=[];
        for(let key in this.questions){
            let ques = this.questions[key];
            ques.isDeletedFromUI=false;
            // dont add question to be deleted to the quesList
            if(ques.Serial_Number__c == event.detail) {
                ques.isDeletedFromUI = true;
            }

            if(ques.Serial_Number__c > event.detail){
                ques.Serial_Number__c= ques.Serial_Number__c -1;
                this.template.querySelectorAll('.multiplechoiceeditcmp').forEach(key => {
                        key.setQuestionSerial(ques.Id,ques.Serial_Number__c);
             
                });
                quesList.push(ques);

            }else{quesList.push(ques);}
        }
        this.questions = quesList;
        if (typeof this.questions== 'undefined' || this.questions.filter(qi => !(qi.isDeletedFromUI === true)).length == 0) {
            this.showIllustration = true;
        }
    }

    @api
    handleStageChange(){
        //code to call method to show reloaded responses on stage change
        let previewComp = this.template.querySelector('.previewComponent');
        if (previewComp) {
            previewComp.handleStageChange();
        }
    }

    @api
    updateSectionAfterProductChange() {
        this.template.querySelectorAll('.previewComponent').forEach(section => {
            console.log("Question Swection comp update questions");
            section.updateQuestionAfterProductChange();
            });
    }

    //P1 Changes
    handleDependentAddition(event){
        if(JSON.parse(JSON.stringify(event.detail)).length>0){
            let questionsOld = JSON.parse(JSON.stringify(this.questions));
            const quesSet  = new Set();
            questionsOld.forEach(element=>{
                quesSet.add(element.Id);
            })

            console.log('event in handleDependentAddition:',JSON.parse(JSON.stringify(event.detail)));
            let newQuesList = JSON.parse(JSON.stringify(event.detail));
            console.log('oldQuestions:',questionsOld);
            let quesListUpdated=[];
            for(var i=0;i<questionsOld.length;i++){
                quesListUpdated.push(questionsOld[i]);
                if(questionsOld[i].Id == newQuesList[0].Parent_Question__c && !quesSet.has(newQuesList[0].Id)){
                    newQuesList.forEach(element=>{
                        quesListUpdated.push(element);
                    })
                }
            }
            this.questions = [];
            console.log('quesListUpdated',quesListUpdated);
            this.questions = quesListUpdated;
        }
    }

    handleDependentDeletion(event){
        //QList-this.questions
        //To be deleted list - event.detail
        //

        console.log('event in handleDependentDeletion:',JSON.parse(JSON.stringify(event.detail)));
        let QuesListToRemove = JSON.parse(JSON.stringify(event.detail));
        

        let ChildQuesList =[];
        ChildQuesList.push(...QuesListToRemove);
        let doRun = true;

        while(doRun){

                let result= this.recusrsiveMethod(ChildQuesList);
                QuesListToRemove.push(...result);
                ChildQuesList = result;
                if(result.length == 0){
                    doRun = false;
                }
        }


        
        let questionsOld = JSON.parse(JSON.stringify(this.questions));
        const quesOldSet  = new Set();
            questionsOld.forEach(element=>{
                quesOldSet.add(element.Id);
            })

        const quesToRemoveSet  = new Set();
        QuesListToRemove.forEach(element=>{
            quesToRemoveSet.add(element.Id);
            })

        let quesListUpdated=[];
        let difference = new Set(
            [...quesOldSet].filter(x => !quesToRemoveSet.has(x)));

        questionsOld.forEach(el=>{
            if(difference.has(el.Id)){
                quesListUpdated.push(el);
            }
        })


        //let quesSetUpdated=questionsOld.filter( ( el ) => !QuesListToRemove.includes( el ) );
        /*questionsOld.forEach(element =>{
            QuesListToRemove.forEach(dp=>{
                if(element.Id != dp.Id){
                    quesListUpdated.push(element);
                }
            })
        })*/
        console.log('quesListUpdated::',quesListUpdated);
        this.questions = quesListUpdated;

    }

    recusrsiveMethod(QList){
        let questionsOriginal = JSON.parse(JSON.stringify(this.questions));
        let childList=[];
        QList.forEach(ques=>{
            let child = questionsOriginal.filter(cQues => cQues.Parent_Question__c == ques.Id);
            childList.push(...child);
        })
        return childList;

    }

    @api
    fetchQuestionIds(){
        console.log('in fetchQuestionIds');
        let arrQuestionIds =[];
        this.questions.forEach(element =>{
            arrQuestionIds.push(element.Id);
        })
        return arrQuestionIds;
    }
}