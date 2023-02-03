/**
*  @Date		:	April 15 2021
*  @Author		: 	Shivam Verma
*  @Description	:	Question Component for handling creation of of questions for Chime Admin
*                   Component supports creation of question, setting question properties, 
*                   publishing of questions, auto save of questions.
*                   Same component is getting reused for dependent questionnaire
*/
import { api, wire, track, LightningElement } from 'lwc';
import { createRecord, deleteRecord, updateRecord } from 'lightning/uiRecordApi';
import QUESTION_OBJECT from '@salesforce/schema/CHIME_Product_Question__c';
import QUESTION_TEXT from '@salesforce/schema/CHIME_Product_Question__c.Question_Text__c';
import EXPECTED_RESPONSE from '@salesforce/schema/CHIME_Product_Question__c.Expected_Response__c';
import POSSIBLE_RESPONSE from '@salesforce/schema/CHIME_Product_Question__c.Possible_Response__c'
import FORM_STAGE from '@salesforce/schema/CHIME_Product_Question__c.Form_Stage__c';
import HELP_TEXT from '@salesforce/schema/CHIME_Product_Question__c.Help_Text__c';
import QUESTION_TYPE from '@salesforce/schema/CHIME_Product_Question__c.Question_Type__c';
import QUESION_ID from '@salesforce/schema/CHIME_Product_Question__c.Id';
import QUESTION_REQUIRED from '@salesforce/schema/CHIME_Product_Question__c.Required__c';
import QUESTION_STATUS from '@salesforce/schema/CHIME_Product_Question__c.Question_Status__c';
import PRODUCT_TEMPLATE from '@salesforce/schema/CHIME_Product_Question__c.Chime_Product_Template__c';
import PRODUCT_ID from '@salesforce/schema/CHIME_Product_Question__c.CHIME_Product__c';
import TEMPLATE_TEXT from '@salesforce/schema/CHIME_Product_Question__c.Template__c';
import QUESTION_SECTION from '@salesforce/schema/CHIME_Product_Question__c.Section__c';
import QUESTION_SERIAL_NUMBER from '@salesforce/schema/CHIME_Product_Question__c.Serial_Number__c';
import QUESTION_SECTION_SERIAL_NUMBER from '@salesforce/schema/CHIME_Product_Question__c.Section_Serial_Number__c';
import QUESTION_EXCLUSION_MARKER from '@salesforce/schema/CHIME_Product_Question__c.Exclusion_marker__c';
import PARENT_QUESTION from '@salesforce/schema/CHIME_Product_Question__c.Parent_Question__c';
import IS_LATEST from '@salesforce/schema/CHIME_Product_Question__c.Is_Latest__c';

//this method is used to point the existing responses to latest versions of question.
import changeResponseQuestionMapping from '@salesforce/apex/QuestionnaireController.changeResponseQuestionMapping';
//this method is used to create dependent clone when parent is updated.
import updateDependentAfterPublish from '@salesforce/apex/QuestionnaireController.createDependentAfterPublish';
//this method is used to create clone of dependent when they are updated in Admin
import createDependentClone from '@salesforce/apex/QuestionnaireController.createDependentClone';



import moveQuestion from '@salesforce/apex/QuestionnaireController.moveQuestion';
//import deleteQuestion from '@salesforce/apex/QuestionnaireController.deleteQuestion';

import mcqQuestionTemplate from './multipleChoiceQuestionEditComponent.html';
import textTemplate from './textQuestionComponent.html';

import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import QUESTIONNAIRE_PUBLISH_MESSAGE from '@salesforce/messageChannel/l2q_QuestionnairePublish__c';
import PREVIEW_PUBLISH from '@salesforce/messageChannel/l2q_PreviewBeforePublish__c';

//CHIME P2 changes
import POC_QUESTION from '@salesforce/schema/CHIME_Product_Question__c.POC_question__c';
import FULL_INTEGRATION_QUESTION from '@salesforce/schema/CHIME_Product_Question__c.Full_Integration_Question__c';

export default class MultipleChoiceQuestionComponent extends LightningElement {
    
    @wire(MessageContext) messageContext;
    subscription = null;
    previewsubscription = null;

    @track question;
    @track questionCopy;

    @track question;
    @api get question() {
        return this.question;
    }
    set question(value) {
        this.question = value;
    }
    @track questionObj;

    @track requiredTypeValue;
    @track questionStageValue;
    @track answerTypeValue;
    value = '';
    @track questionType;
    @track questionChanged=false;
    @track questionToBeDeleted=false;

    @track showpreview = false;
    @api get showpreview() {
        return this.showpreview;
    }
    set showpreview(value) {
        this.showpreview = value;
    }
    @api productid;
    @track deleteQuestion = false;

    @track questionCardClasses = "slds-card question-card";
    questionCardUnblurClasses = "slds-card question-card";

    @track showalldependent=false;
    idUpdatedDueToPublish = false;

    cloningMarker=false;
    beforeCloneId;

    @api showdependentpreview= false;

    connectedCallback() {
        let questionObj = JSON.parse(JSON.stringify(this.question));
        this.questionToBeDeleted= false;
        this.question = questionObj;
        this.questionCopy = questionObj;
        this.questionType = questionObj.Question_Type__c;
        questionObj.Required__c ? this.requiredTypeValue = "Mandatory" : this.requiredTypeValue = "Optional";
        questionObj.Question_Type__c === "Multipicklist" ? this.answerTypeValue = "Multi Select" : this.answerTypeValue = "Single Select";

        this.subscription = subscribe(
            this.messageContext,
            QUESTIONNAIRE_PUBLISH_MESSAGE,
            (message) => {
                this.handlePublish(message);
            });
        this.previewsubscription = subscribe(
            this.messageContext,
            PREVIEW_PUBLISH,
            (message) => {
                this.handlePreviewBeforePublish(message);
            });
        
    }
    handlePreviewBeforePublish(message){
        let msg = JSON.parse(JSON.stringify(message));
        
        if(msg.preview === true){
            this.showpreview = true;
            setTimeout(() => {
                this.showalldependent=true;
            }, 300);
            
            console.log('this.showalldependent ::: '+this.showalldependent);
            console.log('this.showpreview ::: '+this.showpreview);

        }else{
            this.showalldependent=false;
            this.showpreview = false;
        }
    }

    //P1 changes
    renderedCallback() {
        if(this.showdependentpreview){
            this.showpreview = true;
            setTimeout(() => {
                this.showalldependent=true;
            }, 300);
        }
    }

    get requiredOptions() {
        return [
            { label: 'Mandatory', value: 'Mandatory' },
            { label: 'Optional', value: 'Optional' },
        ];
    }

    get requiredTypeName() {
        return 'required-tyoe-'+this.questionCopy.Id;
    }

    get stageOptions() {
        return [
            { label: 'Gating', value: 'Gating' },
            { label: 'Scoping', value: 'Scoping' },
        ];
    }

    get stageTypeName() {
        return 'stage-'+this.questionCopy.Id;
    }

    get questionTypeOptions() {
        return [
            { label: 'Single Select', value: 'Single Select' },
            { label: 'Multi Select', value: 'Multi Select' },
        ];
    }

    get questionTypeName() {
        return 'question-type-'+this.questionCopy.Id;
    }

    render() {

        if (this.questionCopy.Id !== this.question.Id && !this.idUpdatedDueToPublish) { //if the question changed by parent, reset the values
            this.deleteQuestion = false;
            this.questionChanged = false;
            let questionObj = JSON.parse(JSON.stringify(this.question));
            if (!questionObj.Question_Text__c) {
                questionObj.Question_Text__c = '';
            }
            this.questionToBeDeleted= false;
            this.questionCopy = questionObj;
            this.questionType = questionObj.Question_Type__c;
            questionObj.Required__c ? this.requiredTypeValue = "Mandatory" : this.requiredTypeValue = "Optional";
            questionObj.Question_Type__c === "Multipicklist" ? this.answerTypeValue = "Multi Select" : this.answerTypeValue = "Single Select";
        }

        //this.questionCopy = this.question;
        this.questionType = this.question.Question_Type__c;
        return this.questionType == "Text" ? textTemplate : mcqQuestionTemplate;
        
    }

    disconnectedCallback() {
        // Unsubscribe from BearListUpdate__c message
        unsubscribe(this.subscription);
        this.subscription = null;
        unsubscribe(this.previewsubscription);
        this.previewsubscription = null;
      }
    

    handleQuestionTextChange(event) {
        this.questionCopy.Question_Text__c = event.target.value;
        this.questionChanged = true;
        this.handleSave();
    }

    handleQuestionHelpTextChange(event) {
        this.questionCopy.Help_Text__c = event.target.value;
        this.questionChanged = true;
        this.handleSave();
    }

    handleOptionsTextChange(event) {
        let optionsTextValue = event.target.value;
        this.questionCopy.Possible_Response__c = optionsTextValue;
        this.options = optionsTextValue.split("\n");
        this.questionChanged = true;
        this.handleSave();
    }

    handleMandatoryChange(event) {
        let value = event.detail.value;
        value === "Mandatory" ? this.questionCopy.Required__c = true : this.questionCopy.Required__c = false;
        value === "Mandatory" ? this.requiredTypeValue = "Mandatory" : this.requiredTypeValue = "Optional";
        this.questionChanged = true;
        this.handleSave();
    }

    handleStageChange(event) {
        let value = event.detail.value;
        this.questionCopy.Form_Stage__c = value;
        this.questionChanged = true;
        this.handleSave();
    }
    
    handleQuestionTypeChange(event) {
        let value = event.detail.value;
        if (value === "Multi Select") {
            this.questionCopy.Question_Type__c = "Multipicklist"
        }
        value === "Multi Select" ? this.answerTypeValue = "Multi Select" : this.answerTypeValue = "Single Select";
        this.questionChanged = true;
        this.handleSave();
    }

    handlePreview() {
        this.showpreview = true;
    }

    handleEditView() {
        this.showpreview = false;
    }

    handleDeleteQuestion() {
        
        this.deleteQuestion = true;
    }
    handleCancelDeleteQuestion(){
        this.deleteQuestion = false;
    }

    handleDeleteQuestionConfirm() {
        
        /* check if the question is in draft status
        * if yes - delete the question from database and hide from UI
        * if published - just mark questionToBeDeleted and hide from UI
        */
        let questionObj = JSON.parse(JSON.stringify(this.question));

        if (questionObj.Question_Status__c == 'Published') {
            this.questionToBeDeleted=true;
            const fields = {};
            fields[QUESION_ID.fieldApiName] = questionObj.Id;
            fields[QUESTION_EXCLUSION_MARKER.fieldApiName] = true;
            const recordInput = { fields };

            updateRecord(recordInput)
            .then(() => {
                this.questionCopy.Exclusion_marker__c = true;
            })
            .catch(error => {
                    console.log("Error marked excluded : ",error.message);
            })

        }
        else {
            this.deleteQuestion = true;
            deleteRecord(this.question.Id)
            .then(() => {
                this.questionCopy.Exclusion_marker__c = true;
            })
            .catch(error => {
                console.log('some error occurred:'+error);
                
            });
        }
        //Add code here to set the serial number of questions.
        const updateSectionAfterDeleteEvent = new CustomEvent('updateafterdelete', { detail: questionObj.Serial_Number__c });
        this.dispatchEvent(updateSectionAfterDeleteEvent);
    }

    handleQuestionMoveUp() {
        moveQuestion({productId: this.productid, questionId: this.question.Id, sectionName: this.question.Section__c, moveUp: true})
            .then((result) => {
                const updateSectionAfterMoveEvent = new CustomEvent('updateaftermove', { detail: result });
                this.dispatchEvent(updateSectionAfterMoveEvent);
            })
            .catch(error => {
                console.log("error:",error);
            });
    }

    handleQuestionMoveDown() {
        moveQuestion({productId: this.productid, questionId: this.question.Id, sectionName: this.question.Section__c, moveUp: false})
            .then((result) => {
                const updateSectionAfterMoveEvent = new CustomEvent('updateaftermove', { detail: result });
                this.dispatchEvent(updateSectionAfterMoveEvent);
            })
            .catch(error => {
                console.log("error:",error);
            });
    }

    handleSave() {
        
            // Create the recordInput object
            let questionObj = JSON.parse(JSON.stringify(this.questionCopy));
            console.log('inside handle save');
            if (questionObj.Question_Status__c === "Draft") {
            
                const fields = {};
                fields[QUESION_ID.fieldApiName] = questionObj.Id;
                fields[QUESTION_TEXT.fieldApiName] = questionObj.Question_Text__c ? questionObj.Question_Text__c : '';
                fields[HELP_TEXT.fieldApiName] = questionObj.Help_Text__c ? questionObj.Help_Text__c : '';
                fields[POSSIBLE_RESPONSE.fieldApiName] = questionObj.Possible_Response__c ? questionObj.Possible_Response__c : '';
                fields[QUESTION_REQUIRED.fieldApiName] = questionObj.Required__c;
                fields[FORM_STAGE.fieldApiName] = questionObj.Form_Stage__c;
                fields[QUESTION_TYPE.fieldApiName] = questionObj.Question_Type__c;
                fields[QUESTION_SERIAL_NUMBER.fieldApiName] = questionObj.Serial_Number__c;
                //Chime P2 Changes
                fields[POC_QUESTION.fieldApiName] = questionObj.POC_question__c;
                fields[FULL_INTEGRATION_QUESTION.fieldApiName] = questionObj.Full_Integration_Question__c;
                
                //fields[QUESTION_STATUS.fieldApiName] = 'Draft';

                const recordInput = { fields };
                updateRecord(recordInput)
                .then(result => {
                    console.log("Saving as question in draft", result);
                })
                .catch(error => {
                    console.log("error saving :",error);
                });
            }else 
            if(questionObj.Parent_Question__c){
                this.beforeCloneId = questionObj.Id;
                createDependentClone({dependentQuestion : JSON.stringify(this.questionCopy)})
                .then(result =>{
                    this.question = result;
                    this.cloningMarker=true;
                    console.log('result Cloned Object',result);
                })
                .catch(error =>{
                    console.log('error',error);
                })
            }
    }

    @api
    setQuestionSerial(quesId,serialnumber){
        console.log('in setQuestionSerial'+this.question.Id+ ' and'+this.deleteQuestion+'and '+this.questionToBeDeleted);
        if(quesId == this.question.Id){
            console.log('oldSerialNumber:'+this.question.Serial_Number__c + 'newOne:'+serialnumber);
            this.question.Serial_Number__c = serialnumber;
            this.questionCopy.Serial_Number__c = serialnumber;
        }
        if (this.questionCopy.Question_Status__c === "Draft") {
            this.handleSave();
        }
    }

    handlePublish(message) {
        if(this.questionToBeDeleted == false){
            let questionObj1 = JSON.parse(JSON.stringify(this.question));
            if(this.questionChanged == false || questionObj1.Question_Status__c == 'Draft'){
                let questionObj = JSON.parse(JSON.stringify(this.question));
                let msg = JSON.parse(JSON.stringify(message));
                const fields = {};
                fields[QUESION_ID.fieldApiName] = questionObj.Id;
                fields[QUESTION_TEXT.fieldApiName] = questionObj.Question_Text__c;
                fields[HELP_TEXT.fieldApiName] = questionObj.Help_Text__c;
                fields[POSSIBLE_RESPONSE.fieldApiName] = questionObj.Possible_Response__c;
                fields[QUESTION_REQUIRED.fieldApiName] = questionObj.Required__c;
                fields[FORM_STAGE.fieldApiName] = questionObj.Form_Stage__c;
                fields[QUESTION_TYPE.fieldApiName] = questionObj.Question_Type__c;
                fields[QUESTION_STATUS.fieldApiName] = 'Published';
                fields[PRODUCT_TEMPLATE.fieldApiName] = msg.templateid;
                fields[PRODUCT_ID.fieldApiName] = msg.productid;
                fields[PARENT_QUESTION.fieldApiName] = questionObj.Parent_Question__c;
                fields[QUESTION_SECTION.fieldApiName] = questionObj.Section__c;
                fields[QUESTION_SERIAL_NUMBER.fieldApiName] = questionObj.Serial_Number__c;
                fields[QUESTION_SECTION_SERIAL_NUMBER.fieldApiName] = questionObj.Section_Serial_Number__c;
                fields[EXPECTED_RESPONSE.fieldApiName] = questionObj.Expected_Response__c;
                fields[IS_LATEST.fieldApiName] = true;
                //Chime P2 Changes
                fields[POC_QUESTION.fieldApiName] = questionObj.POC_question__c;
                fields[FULL_INTEGRATION_QUESTION.fieldApiName] = questionObj.Full_Integration_Question__c;
                

                if(questionObj.Template__c == undefined || questionObj.Template__c == null){
                    fields[TEMPLATE_TEXT.fieldApiName] = msg.templateid;
                }
                else{
                    fields[TEMPLATE_TEXT.fieldApiName] = questionObj.Template__c + msg.templateid;
                }
                
                const recordInput = { fields };

                console.log('recordInput',recordInput);

                updateRecord(recordInput)
                .then((result) => {
                    console.log('result in Update=',result);
                    this.question.Question_Status__c = 'Published';
                    this.questionCopy.Question_Status__c = 'Published';
                    this.questionChanged = false;
                    this.question.Template__c = questionObj.Template__c + msg.templateid;
                    this.questionCopy.Template__c = questionObj.Template__c + msg.templateid;

                    if(this.cloningMarker){
                        changeResponseQuestionMapping({ oldQues:this.beforeCloneId ,  newQues: questionObj.Id, productId : msg.productid})
                        .then((res) => {
                            console.log('res after changing ID',res);
                            this.cloningMarker=false;
                        })
                        .catch(error => {
                            console.log('error',error);
                        });
                    }
                })
                .catch(error => {
                        console.log("Error publishing : ",error.body.message);
                })
            }
            else{
                let questionObj = JSON.parse(JSON.stringify(this.questionCopy));
                let msg = JSON.parse(JSON.stringify(message));
                const fields = {};
                //fields[QUESION_ID.fieldApiName] = questionObj.Id;
                fields[QUESTION_TEXT.fieldApiName] = questionObj.Question_Text__c;
                fields[HELP_TEXT.fieldApiName] = questionObj.Help_Text__c;
                fields[POSSIBLE_RESPONSE.fieldApiName] = questionObj.Possible_Response__c;
                fields[QUESTION_REQUIRED.fieldApiName] = questionObj.Required__c;
                fields[FORM_STAGE.fieldApiName] = questionObj.Form_Stage__c;
                fields[QUESTION_STATUS.fieldApiName] = 'Published';
                fields[PRODUCT_TEMPLATE.fieldApiName] = msg.templateid;
                fields[PRODUCT_ID.fieldApiName] = msg.productid;
                fields[QUESTION_SECTION.fieldApiName] = questionObj.Section__c;
                fields[QUESTION_SERIAL_NUMBER.fieldApiName] = questionObj.Serial_Number__c;
                fields[QUESTION_SECTION_SERIAL_NUMBER.fieldApiName] = questionObj.Section_Serial_Number__c;
                fields[PARENT_QUESTION.fieldApiName] = questionObj.Parent_Question__c;
                fields[QUESTION_TYPE.fieldApiName] = questionObj.Question_Type__c;
                fields[TEMPLATE_TEXT.fieldApiName] = msg.templateid;
                fields[EXPECTED_RESPONSE.fieldApiName] = questionObj.Expected_Response__c;
                fields[IS_LATEST.fieldApiName] = true;
                //Chime P2 Changes
                fields[POC_QUESTION.fieldApiName] = questionObj.POC_question__c;
                fields[FULL_INTEGRATION_QUESTION.fieldApiName] = questionObj.Full_Integration_Question__c;
                
                const recordInput = { apiName: QUESTION_OBJECT.objectApiName, fields };

                createRecord(recordInput)
                .then((result) => {
                    console.log("Question published",result);
                    console.log('Id from question',JSON.parse(JSON.stringify(this.question)));
                    console.log('Id from questionCopy',JSON.parse(JSON.stringify(this.questionCopy)));
                    this.idUpdatedDueToPublish = true;
                    let questionClone = {...this.question};
                    questionClone.Id = result.id;
                    this.question = questionClone;
                    this.questionCopy.Id = result.id;
                    this.questionChanged = false;
                    //we will have new ID here
                    changeResponseQuestionMapping({ oldQues:questionObj.Id ,  newQues: result.id, productId : msg.productid})
                    .then((res) => {
                        console.log('res after changing ID',res);
                    })
                    .catch(error => {
                        console.log('error',error);
                    });
                    updateDependentAfterPublish({ oldQuestionId:questionObj.Id ,  createdQuestionId: result.id, templateId : msg.templateid})
                    .then((res) => {
                        console.log('updated dependents',res);
                    })
                    .catch(error => {
                        console.log('error',error);
                    });

                }).then ( () => {
                    this.idUpdatedDueToPublish = false;
                })
                .catch(error => {
                        console.log("Error publishing : ",error);
                })
            }
        }
    }

    //CHIME - P2 Changes - SFDC-8029
    handleChangePOCQues(event) {
        let value = event.detail.checked;
        this.questionCopy.POC_question__c = value;
        this.questionChanged = true;
        this.handleSave();
    }
    
    handleChangeFullIntegrationQues(event) {
        let value = event.detail.checked;
        this.questionCopy.Full_Integration_Question__c = value;
        this.questionChanged = true;
        this.handleSave();
    }
}