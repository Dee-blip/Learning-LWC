/**
*  @Date		:	April 15 2021
*  @Author		: 	Shivam Verma
*  @Description	:	Preview Component for handling preview of questions
*                   Same component will be reused for Preview in Admin, dependent, 
*                   Chime Internal forms and Chime External Forms
*/
import { api, track, wire, LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createRecord, updateRecord } from 'lightning/uiRecordApi';

import RESPONSE_OBJECT from '@salesforce/schema/CHIME_Response__c';
import RESPONSE_ID from '@salesforce/schema/CHIME_Response__c.Id';
import RESPONSE_CHIME from '@salesforce/schema/CHIME_Response__c.CHIME__c';
import RESPONSE_QUESTION from '@salesforce/schema/CHIME_Response__c.CHIME_Product_Question__c';
import RESPONSE from '@salesforce/schema/CHIME_Response__c.Response__c';

import getQuestionResponse from '@salesforce/apex/QuestionnaireController.getQuestionResponse';

import mcqQuestionTemplate from './multipleChoiceQuestionPreviewComponent.html';
import textTemplate from './textQuestionPreviewComponent.html';
import mcqQuestionAdminTemplate from './multipleChoiceQuestionAdminPreviewComponent.html';

//code for refresh component
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import QUESTIONNAIRE_PUBLISH_MESSAGE from '@salesforce/messageChannel/l2q_QuestionnairePublish__c';
import getInvalidTextResponses from '@salesforce/apex/ChimeTriggerClass.getInvalidTextResponses';

import STAGE_TRANSITION from '@salesforce/messageChannel/L2Q_ChimeStageTransition__c';

//P1 Changes
import getDependentQuestionsForParentInChimeForm from '@salesforce/apex/QuestionnaireController.getDependentQuestionsForParentInChimeForm';

export default class MultipleChoiceQuestionPreviewComponent extends LightningElement {
    @wire(MessageContext) messageContext;
    subscription = null;
    subscriptionForStage = null;

    @api question;

    @track getQuestin
    @api isAdminMode;
    @api chimeid;
    @api previewmode;
    @api showdependent;
    @api fromadmin;
    @api classvalues;

    @track showHelpText = false;
    @track selectedOptions;

    @track optionsMap = [];
    @track responseValuesForSingleSelect;
    @track responseValuesForMultiSelect = [];

    @track optionSelected = false;
    @track chimeFormMode = false;
    @track hasParent = false;
    @track showDependentOnSelection = false;
    @track userSelectionForDependents;
    @track questionCopy;

    @track optionClasses;
    optionUnselectedClasses = "slds-col slds-size_8-of-8 slds-p-left_large slds-p-right_x-large slds-p-bottom_medium optionUnselected";

    @track questionType;
    @track response;
    @track textResponse;
    @track textResponseStarted = false;
    @track previousValue;
    @track isPaste;

    @track showDependentAdmin = true;
    @track isMultiSelect;
    @track refreshTextResponse = true;

    @api showalldependent;

    invalidTextResponseList;

    @api responseDisable=false;
    
    @api chimeStage;
    @api chimeStatus;

    //P1 changes
    //to be used for showing preview of n level of dependents.
    @api showdependentpreview = false;

    handleShowHelpText() {
        this.showHelpText = !this.showHelpText;
    }

    savePreviousValue(event) {
    	// Only track previous value on focus,Ignore if called by paste event
    	// this will make sure when genuine onblur is triggered, previous value
    	// tracks the real value before series of copy-pastes
        if (this.isPaste === undefined || this.isPaste === false){
            this.previousValue = event.target.value;
        }
    }

    connectedCallback() {
        this.showalldependent = false;
        this.refreshTextResponse = true;
        this.questionType = this.question.Question_Type__c;
        let questionObj = JSON.parse(JSON.stringify(this.question));
        //P1 Changes
        this.questionCopy = questionObj;
        //console.log("Connected callback :::: Question :: ", questionObj);
        if (!this.fromadmin) {
            this.getQuestionOptions(questionObj);
        } else {
            if (this.question.Question_Type__c != 'Text' && this.question.Possible_Response__c) {
                //console.log("From admin - load options");
                let options = this.question.Possible_Response__c.split("\n");
                for (const option of options) {
                    this.optionsMap.push({ label: option, value: option, showDepentent: false });
                }
            }
        }
        //Change after passing stage and status from parent components.
        //console.log('chimeStage', this.chimeStage);
        console.log('responseDisable', this.responseDisable);
        if(this.responseDisable == false){
            if(this.chimeStage == 'Closed' || (this.chimeStage == 'Integration' && this.chimeStatus != 'Reopened')){
                this.responseDisable =true;
            }else{
                this.responseDisable =false;
            }
        }
        
        this.subscriptionForStage = subscribe(
            this.messageContext,
            STAGE_TRANSITION,
            (message) => {
                console.log('Got the STAGE_TRANSITION message', message);
                if(message.readOnly === true){
                    this.responseDisable =true;
                }else{
                    this.responseDisable =false;
                }
            });

        //for questionnaire refresh
        this.subscription = subscribe(
            this.messageContext,
            QUESTIONNAIRE_PUBLISH_MESSAGE,
            (message) => {
                //this.handlePublish(message);
                //console.log('Got the message', message);
            });

        this.getInvalidResponses();
    }

    disconnectedCallback() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    makeUnclickable(){
        //console.log('making Unclickable in preview');
    }


    previewCalledFromEditCmp() {
        //console.log('inside previewCalledFromEditCmp');
        setTimeout(() => {
            this.showDependentAdmin = true;
            this.showDependentOnSelection = true;
        }, 100);
        if (this.question.Question_Type__c != "Text" && this.question.Possible_Response__c) {
            let options = this.question.Possible_Response__c.split("\n");
            this.optionsMap = [];
            for (const option of options) {
                this.optionsMap.push({ label: option, value: option, showDepentent: true });
            }
            this.showdependentpreview = true;
        }
    }

    render() {
        //console.log("render preview");
        if (this.showalldependent) {
            //console.log("Render preview dependent");
            this.previewCalledFromEditCmp();
        }

        /*if (JSON.parse(JSON.stringify(this.questionCopy)) !== JSON.parse(JSON.stringify(this.question))) {
            this.getPreviousResponse(JSON.parse(JSON.stringify(this.question)));
            this.questionCopy = this.question;
        }*/
        ////console.log("Preview render type :" + this.questionType);
        ////console.log("From admin ::: "+this.fromadmin);

        if (this.questionCopy.Id !== this.question.Id){
            let questionObj = JSON.parse(JSON.stringify(this.question));
            this.questionType = questionObj.Question_Type__c;
            this.questionCopy = questionObj;
            this.template.querySelector('.question-card').classList.remove('glowQuestionsWithResponses');
            //to load options
            if (!this.fromadmin) {
                this.getQuestionOptions(questionObj);
            }
        }
        this.questionType = this.question.Question_Type__c;
        if (this.questionType == "Text") {
            return textTemplate;
        } else {
            if (this.fromadmin) {
                return mcqQuestionAdminTemplate;
            } else {
                return mcqQuestionTemplate;
            }
        }

    }

    renderedCallback() {
        if (!this.fromadmin) {
            //Grey out as its a dependent question
            if (this.classvalues === "dependent") {
                this.template.querySelector('.question-card').classList.add('dependent-question');
            }

            const style = document.createElement('style');
            style.innerText = `.slds-radio {
                                            padding-botton: 0.4%;
                                            }`;
            this.template.querySelectorAll(".lightning-radiogroup_radiogroup")
                .forEach((elmt) => {
                    //console.log("Adding padding");
                    elmt.appendChild(style);
                });
        }

        /*if(showdependentpreview){
            this.previewCalledFromEditCmp();
        }*/
    }

    @api
    updateQuestionAfterProductChange() {
        //console.log("Update question due to product change");
        //console.log(this.question);
        //console.log("QUestion : ", JSON.parse(JSON.stringify(this.question)));
        this.getQuestionOptions(JSON.parse(JSON.stringify(this.question)));
    }

    getInvalidResponses() {
        getInvalidTextResponses()
            .then(result => {
                this.invalidTextResponseList = result;
            })
            .catch(error => {
                this.error = error;
            });
    }

    getQuestionOptions(questionObj) {

        questionObj.Parent_Question__c ? this.hasParent = true : this.hasParent = false;
        this.optionClasses = this.optionUnselectedClasses;
        this.questionType = questionObj.Question_Type__c;
        this.isAdminMode = false;
        this.textResponse = "";

        ////console.log("Question ::: "+questionObj.Id + "   is of type : "+questionObj.Question_Type__c);
        if (questionObj.Question_Type__c === "Multipicklist") {
            //console.log("Setting question type Multipicklist ");
            this.isMultiSelect = true;
        } else {
            this.isMultiSelect = false;
        }
        //console.log("Question set to :::: " + this.isMultiSelect);


        this.responseValuesForMultiSelect = [];
        this.responseValuesForSingleSelect = '';
        this.selectedOptions = '';
        this.response = null;
        this.questionType = "";
        this.questionType = questionObj.Question_Type__c;
        ////console.log("Qiestion id ::: "+questionObj.Id + "  :: Chime Id :: "+this.chimeid);
        getQuestionResponse({ questionId: questionObj.Id, chimeId: this.chimeid })
            .then((result) => {
                //console.log("Response :", result);
                let optionsText = questionObj.Possible_Response__c;

                if (result !== undefined && result !== null) {
                    this.response = result;
                    let resultObj = JSON.parse(JSON.stringify(result));
                    let existingResponse = [];

                    if (this.isMultiSelect) {
                        this.responseValuesForMultiSelect = resultObj.Response__c;
                        existingResponse = resultObj.Response__c;
                    } else {
                        this.responseValuesForSingleSelect = resultObj.Response__c;
                        existingResponse.push(resultObj.Response__c);
                    }

                    if (this.questionType == "Text") {
                        this.textResponse = resultObj.Response__c;
                    } else {
                        if (optionsText !== undefined) {
                            let options = questionObj.Possible_Response__c.split("\n");
                            //console.log("Possible option ::: " + options);
                            this.optionsMap = [];
                            for (const option of options) {
                                if (existingResponse.includes(option)) {
                                    this.optionsMap.push({ label: option, value: option, showDepentent: true });
                                    this.selectedOptions = option;
                                } else {
                                    this.optionsMap.push({ label: option, value: option, showDepentent: false });
                                }
                            }

                            let optionForDependentShow = JSON.parse(JSON.stringify(this.optionsMap));
                            optionForDependentShow.forEach(elem =>{
                                if(elem.showDepentent == true){
                                    getDependentQuestionsForParentInChimeForm ( {parentQuestionId: this.question.Id, expectionResponse: elem.value, productId: this.question.CHIME_Product__c, chimeId : this.chimeid})
                                    .then (result => {
                                        //console.log("result for getDependentQuestionsForParentInChimeForm ",result);
                                        if(result.length>-1){
                                            this.dispatchEvent(new CustomEvent('adddependentquestion', { 
                                                bubbles: true, 
                                                composed: true,
                                                detail : JSON.parse(JSON.stringify(result)) 
                                            }));
                                        }
                                    })
                                    .catch(error => {
                                        console.log("Error getting the result",error);
                                    });
                                }
                            })
                        }
                    }
                    this.template.querySelector('.question-card').classList.add('glowQuestionsWithResponses');
                    setTimeout(() => {
                        this.showDependentOnSelection = true;
                    }, 100);
                } else {
                    if (this.questionType == "Text") {
                        this.textResponse = "";
                    } else {
                        if (optionsText !== undefined) {
                            let options = questionObj.Possible_Response__c.split("\n");
                            //console.log("Possible option when no response ::: " + options);
                            this.optionsMap = [];
                            for (const option of options) {
                                this.optionsMap.push({ label: option, value: option, showDepentent: false });
                            }
                        }
                    }
                }
            }).then(() => {
                this.template.querySelectorAll('.dependentquestion').forEach(dependent => {
                    //console.log("Updating dependent after product change");
                    dependent.handleProductChangeForDependents();
                });
            })
            .catch(error => {
                console.log("Error getting the result",error);
                //console.log(error.message);
            });
        this.refreshTextResponse = false;
        setTimeout(() => {
            this.refreshTextResponse = true;
        }, 300);
        //console.log("optionsMap ::: ", JSON.parse(JSON.stringify(this.optionsMap)));
        //console.log("responseValuesForMultiSelect ::: ", this.responseValuesForMultiSelect);
        //console.log("responseValuesForSingleSelect ::: ", this.responseValuesForSingleSelect);
    }

    pasteEvent(){
      //   to make sure we dont call save in paste event
       this.isPaste = true;
    }

    getDependentQuestions(response){
        let resp =[];
        getDependentQuestionsForParentInChimeForm ( {parentQuestionId: this.question.Id, expectionResponse: response, productId: this.question.CHIME_Product__c, chimeId : this.chimeid})
            .then (result => {
                //console.log("result for getDependentQuestionsForParentInChimeForm ",result);
                
                resp = result;
                return resp;
            })
            .catch(error => {
                console.log("Error getting the result",error);
                return resp;
            });
            
    }

    handleUserResponse(event) {
        //P1 changes
        //This below code will fetch the dependent for previous response to remove them from UI.
        if (!this.fromadmin) {
            let previousResponse ;
            if (this.isMultiSelect) {
                let prevRes =[];
                prevRes = this.regexMethodForMultiselect(this.responseValuesForMultiSelect);
                //console.log('prevRes',prevRes);
                //previousResponse = this.responseValuesForMultiSelect.split(",");
                prevRes.forEach(el =>{
                    getDependentQuestionsForParentInChimeForm ( {parentQuestionId: this.question.Id, expectionResponse: el, productId: this.question.CHIME_Product__c, chimeId : this.chimeid})
                        .then (result => {
                            console.log("result for getDependentQuestionsForParentInChimeForm ",result);
                            if(result.length>-1){
                                this.dispatchEvent(new CustomEvent('removedependentquestion', { 
                                    bubbles: true, 
                                    composed: true,
                                    detail : JSON.parse(JSON.stringify(result)) 
                                }));
                            }
                        })
                        .catch(error => {
                            console.log("Error getting the result",error);
                        });
                })

            } else {
                previousResponse = this.responseValuesForSingleSelect;
                //for deletion
                getDependentQuestionsForParentInChimeForm ( {parentQuestionId: this.question.Id, expectionResponse: previousResponse, productId: this.question.CHIME_Product__c, chimeId : this.chimeid})
                .then (result => {
                    console.log("result for getDependentQuestionsForParentInChimeForm ",result);
                    if(result.length>-1){
                        this.dispatchEvent(new CustomEvent('removedependentquestion', { 
                            bubbles: true, 
                            composed: true,
                            detail : JSON.parse(JSON.stringify(result)) 
                        }));
                    }
                })
                .catch(error => {
                    console.log("Error getting the result",error);
                });
            }

            
        }

        
        //If Chime mode, upsert the response for Chime forms
        if (!this.fromadmin) {
            let userReponse = event.target.value;
            if (this.isMultiSelect) {
                userReponse = JSON.stringify(userReponse);
            }
            this.handleDependentQuestion(userReponse);
            // dont call upsert if user response has not changed in text question type
            if (this.questionType == "Text") {
                this.isPaste = false;
                setTimeout(() => {
                	// Dont save in case of Paste event (paste also triggers blur)
                    // Timeout ensures that isPaste variable is set properly by pasteEvent()
                    if(this.isPaste === false){
                    
                    	let responseText = userReponse;
                    	responseText = responseText.trim();
                    	responseText = responseText.replace(/(<([^>]+)>)/ig, '');
                    	responseText = responseText.toLowerCase();

                        if (this.previousValue != userReponse) {
                            this.upsertResponse(userReponse);
                        }
                    }
                }, 300);
            }
            else {
                this.upsertResponse(userReponse);
            }
        }
        else {
            let optionVal = event.currentTarget.dataset.id;
            this.handleDependentQuestion(optionVal);
        }
    }

    handleDependentQuestion(userResponse) {
        let optionVal;

        //Show dependent on option clicked
        this.showDependentOnSelection = false;
        setTimeout(() => {
            this.showDependentOnSelection = true;
        }, 100);

        this.userSelectionForDependents = userResponse;

        let optionsList = [];
        if (this.isMultiSelect) {
            optionsList = userResponse;
        } else {
            optionsList.push(userResponse);
        }
        ////console.log("handleDependentQuestion userResponse ::: "+userResponse);
        if (userResponse) {
            let optionsMapUpdated = [];
            let optionMapOld = [...JSON.parse(JSON.stringify(this.optionsMap))];
            for (const option of optionMapOld) {
                if (optionsList.includes(option.label)) {
                    optionsMapUpdated.push({ label: option.label, value: option.label, showDepentent: true });
                    this.selectedOptions = optionVal;
                } else {
                    optionsMapUpdated.push({ label: option.label, value: option.label, showDepentent: false });
                }
            }
            this.optionsMap = [...optionsMapUpdated];
            ////console.log("updated optionsMap ::::: ",this.optionsMap);
        }
    }

    upsertResponse(userResponse) {
        //console.log("response :", this.response);
        let questionObj = JSON.parse(JSON.stringify(this.question));

        const fields = {};
        fields[RESPONSE.fieldApiName] = userResponse;
        fields[RESPONSE_CHIME.fieldApiName] = this.chimeid;

        if (this.response) {
            //console.log("response object ::: ", this.response);
            let responseObj = JSON.parse(JSON.stringify(this.response));
            //console.log("response object parsed ::: ", responseObj);
            fields[RESPONSE_ID.fieldApiName] = responseObj.Id ? responseObj.Id : responseObj.id;
            fields[RESPONSE_QUESTION.fieldApiName] = responseObj.CHIME_Product_Question__c;
            //console.log("fields ::: ", fields);
            const recordInput = { fields };

            updateRecord(recordInput)
                .then(result => {
                    //this.dispatchEvent(new CustomEvent('checkchimestage', { bubbles: true, composed: true }));
                    this.response = result;
                    //update values to new response.
                    //P1 Changes - for adding Dependent questions.
                    if (this.isMultiSelect) {
                        this.responseValuesForMultiSelect = userResponse;
                        let options = [];
                        options = this.regexMethodForMultiselect(this.responseValuesForMultiSelect);
                        options.forEach(el=>{
                            getDependentQuestionsForParentInChimeForm ( {parentQuestionId: this.question.Id, expectionResponse: el, productId: this.question.CHIME_Product__c, chimeId : this.chimeid})
                            .then (result => {
                                console.log("updateRecord if getDependentQuestionsForParentInChimeForm ",result);
                                if(result.length>-1){
                                    this.dispatchEvent(new CustomEvent('adddependentquestion', { 
                                        bubbles: true, 
                                        composed: true,
                                        detail : JSON.parse(JSON.stringify(result)) 
                                    }));
                                }
                                setTimeout(() => {
                                    this.dispatchEvent(new CustomEvent('checkchimestage', { bubbles: true, composed: true }));
                                }, 200);
                            })
                            .catch(error => {
                                console.log("Error getting the result",error);
                            }); 
                        })
                    } else {
                        this.responseValuesForSingleSelect=userResponse;
                        getDependentQuestionsForParentInChimeForm ( {parentQuestionId: this.question.Id, expectionResponse: userResponse, productId: this.question.CHIME_Product__c, chimeId : this.chimeid})
                        .then (result => {
                            console.log("updateRecord else getDependentQuestionsForParentInChimeForm ",result);
                            if(result.length>-1){
                                this.dispatchEvent(new CustomEvent('adddependentquestion', { 
                                    bubbles: true, 
                                    composed: true,
                                    detail : JSON.parse(JSON.stringify(result)) 
                                }));
                            }
                            setTimeout(() => {
                                this.dispatchEvent(new CustomEvent('checkchimestage', { bubbles: true, composed: true }));
                            }, 200);
                        })
                        .catch(error => {
                            console.log("Error getting the result",error);
                        });
                    }
                })
                .catch(error => {
                    console.log('error saving response:' + JSON.stringify(error));
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error saving response',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                });
        } else {
            //console.log("creating user response");
            fields[RESPONSE_QUESTION.fieldApiName] = questionObj.Id;

            const recordInput = { apiName: RESPONSE_OBJECT.objectApiName, fields };
            //console.log("recordInput ::: " + recordInput);
            createRecord(recordInput)
                .then(result => {
                    //this.dispatchEvent(new CustomEvent('checkchimestage', { bubbles: true, composed: true }));
                    this.response = result;
                    //update values to new response.

                    //P1 Changes - for adding Dependent questions.
                    if (this.isMultiSelect) {
                        this.responseValuesForMultiSelect = userResponse;
                        let options = [];
                        options = this.regexMethodForMultiselect(this.responseValuesForMultiSelect);
                        options.forEach(el=>{
                            getDependentQuestionsForParentInChimeForm ( {parentQuestionId: this.question.Id, expectionResponse: el, productId: this.question.CHIME_Product__c, chimeId : this.chimeid})
                            .then (result => {
                                console.log("createRecord if getDependentQuestionsForParentInChimeForm ",result);
                                if(result.length>-1){
                                    this.dispatchEvent(new CustomEvent('adddependentquestion', { 
                                        bubbles: true, 
                                        composed: true,
                                        detail : JSON.parse(JSON.stringify(result)) 
                                    }));
                                }
                                setTimeout(() => {
                                    this.dispatchEvent(new CustomEvent('checkchimestage', { bubbles: true, composed: true }));
                                }, 200);
                            })
                            .catch(error => {
                                console.log("Error getting the result",error);
                            }); 
                        })
                    } else {
                        this.responseValuesForSingleSelect=userResponse;
                        getDependentQuestionsForParentInChimeForm ( {parentQuestionId: this.question.Id, expectionResponse: userResponse, productId: this.question.CHIME_Product__c, chimeId : this.chimeid})
                        .then (result => {
                            console.log("createRecord else getDependentQuestionsForParentInChimeForm ",result);
                            if(result.length>-1){
                                this.dispatchEvent(new CustomEvent('adddependentquestion', { 
                                    bubbles: true, 
                                    composed: true,
                                    detail : JSON.parse(JSON.stringify(result)) 
                                }));
                            }
                            setTimeout(() => {
                                this.dispatchEvent(new CustomEvent('checkchimestage', { bubbles: true, composed: true }));
                            }, 200);
                        })
                        .catch(error => {
                            console.log("Error getting the result",error);
                        });
                    }
                    //----
                    
                })
                .then(()=>{
                    //this.dispatchEvent(new CustomEvent('checkchimestage', { bubbles: true, composed: true }));
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error creating response.',
                            message: error.body.message,
                            variant: 'error',
                        }),
                    );
                });
        }
        this.template.querySelector('.question-card').classList.add('glowQuestionsWithRecentResponses');
    }

    @api
    handleStageChange() {
        //console.log('Inside Preview Component');
        let questionObj = JSON.parse(JSON.stringify(this.question));
        this.getQuestionOptions(JSON.parse(JSON.stringify(questionObj)));
        /*getQuestionResponse({ questionId: questionObj.Id, chimeId: this.chimeid })
            .then((result) => {
                ////console.log("Response :", result);
                let resultObj = JSON.parse(JSON.stringify(result));
                ////console.log('result',result);
                this.response = result;
                let optionsText = this.question.Possible_Response__c;
                ////console.log("Result of response :",result);
                if (resultObj) {
                    //console.log("handleStageChange Result obj");
                    //console.log(resultObj);


                    if (this.questionType == "Text") {
                        this.textResponse = resultObj.Response__c;
                    } else {
                        if (optionsText !== undefined) {
                            let options = this.question.Possible_Response__c.split("\n");
                            for (const option of options) {
                                //console.log("option : " + option + "  :::: result: " + resultObj.Response__c);
                                if (option.includes(resultObj.Response__c)) {
                                    //console.log("True enter ");
                                    this.optionsMap.push({ label: option.label, value: true, showDepentent: false });
                                    this.selectedOptions = option;
                                } else {
                                    //console.log("false enter ");
                                    this.optionsMap.push({ key: option, value: false, showDepentent: false });
                                }
                            }
                            //console.log("Options Map");
                            //console.log(JSON.parse(JSON.stringify(this.optionsMap)));
                        }
                    }
                    setTimeout(() => {
                        this.showDependentOnSelection = true;
                    }, 100);
                } else {
                    if (this.questionType == "Text") {
                        this.responseText = "";
                    } else {
                        if (optionsText !== undefined) {
                            let options = this.question.Possible_Response__c.split("\n");
                            for (const option of options) {
                                this.optionsMap.push({ key: option, value: false, showDepentent: false });
                            }
                        }
                    }
                }

                //const updateSectionAfterMoveEvent = new CustomEvent('updateaftermove', { detail: result });
                //this.dispatchEvent(updateSectionAfterMoveEvent);
            })
            .catch(error => {
                //console.log("Error getting the result");
            });*/
    }

    regexMethodForMultiselect(str){
        let prevRes =[];
        //Regex Code to process the response values.
        const regex = /(["])([0-9A-Za-z]+)(["])/g;
        //const str = this.responseValuesForMultiSelect;
        let m;

        while ((m = regex.exec(str)) !== null) {
            // This is necessary to avoid infinite loops with zero-width matches
            if (m.index === regex.lastIndex) {
                regex.lastIndex++;
            }
            
            // The result can be accessed through the `m`-variable.
            m.forEach((match, groupIndex) => {
                //console.log(`Found match, group ${groupIndex}: ${match}`);
                if(groupIndex ==2){
                    //console.log(`Found match, group ${groupIndex}: ${match}`);
                    prevRes.push(match);
                }
            });
        }
        return prevRes;
    }

}