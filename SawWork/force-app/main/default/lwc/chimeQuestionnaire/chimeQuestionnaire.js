/**
*  @Date		:	Feb 2021
*  @Author		: 	Shivam Verma
*  @Description	:	Top component in the Chime Admin Questionanaire, hold multiple sections and toolkit component
*/
import { api, track, LightningElement } from 'lwc';

//import scopingTemplate from './chimeQuestionnaire.html';
//import gatingTemplate from './chimeQuestionnaireGating.html';

//import { CurrentPageReference } from 'lightning/navigation';
import { subscribe }  from 'lightning/empApi';
import checkRefresh from '@salesforce/apex/QuestionnaireController.checkProductQuestionnaireRefresh';
import checkChimeEligibilityForRefresh from '@salesforce/apex/QuestionnaireController.checkChimeEligibilityForRefresh';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import clearFlag2 from '@salesforce/apex/ChimeTriggerClass.clearFlag2';

export default class ChimeQuestionnaire extends NavigationMixin(LightningElement) {
//Listen to Platform events
    subscription = {};
    @api channelName = '/event/Chime_Question__e';


    @api productid;
    @api stage;
    @api chimeid;
    @api iscustomerfacing;
    @track isGating;

    @track activeSections = ['Gating','Scoping'];

    @track previewmode = true;
    @track showIllustration = false;

    //P1 changes
    @api chimeStage;
    @api chimeStatus;
    @api responseDisable; //To implement read only permissions.

    //CHIME P2 change
    @api ispoc=false;

    connectedCallback() {
        if (this.productid === undefined && this.productid == "") {
            this.showIllustration = true;
        }
        console.log("Chime questionnaire - productid :"+this.productid);
        //console.log("Chime questionnaire - chimeid :"+this.chimeid);
        //console.log("Chime questionnaire - stage :"+this.stage);
        //alert('connectedcallbackproductid'+this.productid);
        if (this.stage == "Gating") {
            this.isGating = true;
            //activeSections.push('Gating');
        }
        this.handleSubscribe();
    }

    handleSubscribe() {
        //console.log('chimeidentity'+chimeidentity);
        // Callback invoked whenever a new event message is received
        const thisReference = this;
        const messageCallback = function(response) {
            //alert('handleSubscribeproductid'+this.productid);
            //console.log('New message received 1: ', JSON.stringify(response));
            //console.log('New message received 2: ', response);
            
            var obj = JSON.parse(JSON.stringify(response));
            //console.log('New message received 4: ', obj);
            //console.log('New message received 5: ', obj.data.payload.Product_ID__c);
            //console.log('Product Id in cmp'+thisReference.productid);
           

            //check if this Chime form has the eligibility to refresh or not

            checkChimeEligibilityForRefresh({ChimeId: thisReference.chimeid})
            .then((refreshResult) => {
                console.log('Eligibility:',refreshResult);
                if(refreshResult == true){

                    //thisReference.dispatchEvent(evt);
                    // Response contains the payload of the new message received
                    var products = [];
                    checkRefresh({ChimeId: thisReference.chimeid})
                    .then((result) => {
                        //console.log('Result from Refresh:'+result);
                        products = result;
                        //console.log('Result from Refresh: Products',products);
                        //console.log('check includes:'+ products.includes("aXiL000000000QrKAI"));

                        //Check if currently openend product is the one for which questionnaire has been changed | give the toast with refresh option
                        if(thisReference.productid == obj.data.payload.Product_ID__c){
                            //console.log('in here');
                            thisReference[NavigationMixin.GenerateUrl]({
                                type: 'standard__recordPage',
                                attributes: {
                                    recordId: thisReference.chimeid,
                                    actionName: 'view',
                                },
                            }).then(url => {
                                //console.log('in here too '+window.location.href);
                                //const loc =  new URL( window.location.href);
                                console.log('url: '+url);
                                const event = new ShowToastEvent({
                                    "title": "The Questionnaire for this Product has been changed.",
                                    "message": "Publisher notes: "+obj.data.payload.Publish_Notes__c + ". Please refresh the Page to see latest changes!",
                                    "variant": 'warning',
                                    "mode":"sticky",
                                    
                                });
                                thisReference.dispatchEvent(event);
                            });
                                //thisReference.clearChimeProductFlag();
                                clearFlag2({ chimeId : thisReference.chimeid , prdtId : obj.data.payload.Product_ID__c })
                                .then(result => {
                                    console.log('Success in clearFlag2',result);
                                })
                                .catch(error => {
                                    console.log('error in clearFlag2',error);
                                });
                            const divblock = thisReference.template.querySelector('[data-id="questionnaireblock"]');
                            if(divblock){
                                thisReference.template.querySelector('[data-id="questionnaireblock"]').className='unclickable';
                            }
                        }
                        //Check if the product for which questionnaire was changed exist in Chime Products
                        else if(products.includes(obj.data.payload.Product_ID__c)){
                            //Product exist in the list so give the toast.
                            const event = new ShowToastEvent({
                                title: 'The questionnaire for Product '+ obj.data.payload.Product_Name__c + ' has been changed.',
                                message: 'Publisher notes: '+obj.data.payload.Publish_Notes__c,
                                mode:'sticky',
                                variant: 'warning',
                            });
                            thisReference.dispatchEvent(event);
                            //setTimeout(thisReference.clearChimeProductFlag,3000);
                            clearFlag2({ chimeId : thisReference.chimeid , prdtId : obj.data.payload.Product_ID__c })
                            .then(result => {
                                console.log('Success in clearFlag2',result);
                            })
                            .catch(error => {
                                console.log('error in clearFlag2',error);
                            });
                        }
                    })
                    .catch(error => {
                        console.log('error',error);
                    });
                }
            })
            .catch(error => {
                console.log('error',error);
            });
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, messageCallback).then(response => {
            // Response contains the subscription information on subscribe call
            console.log('Subscription request sent to: ', JSON.stringify(response.channel));
            this.subscription = response;
        });
    }
    clearChimeProductFlag(){
        //clear the Questionnaire_Changed__c flag on the Chime_Product_Association__c object after notification has been shown
        console.log('listCPA:'+ JSON.stringify(this.listCPA));
        clearFlag2({ chimeId : this.chimeid , prdtId : this.productid })
        .then(result => {
            console.log('Success in clearFlag2',result);
        })
        .catch(error => {
            console.log('error in clearFlag2',error);
        });
    }
    /*render() {
            //let questionObj = JSON.stringify(this.question);
            //console.log("Inside render question in edit");
            console.log(this.isGating);
            return this.isGating ? gatingTemplate : scopingTemplate;
            retu
    }*/

    @api
    handleProductChange(productId, stage, chimeid) {
        console.log("inside handle product change.");
        if(this.iscustomerfacing){
            this.template.querySelector('.questionComponent3').handleProductChange(productId,stage,chimeid);
        }
        else{
        this.showIllustration = false;
        this.productid = productId;
        let questionnaireComp = this.template.querySelector('.questionComponent');
        if (questionnaireComp) {
            questionnaireComp.handleProductChange(productId,'Gating',chimeid);
        }
        let questionnaireComp2 = this.template.querySelector('.questionComponent2');
        if (questionnaireComp2) {
            questionnaireComp2.handleProductChange(productId,'Scoping',chimeid);
        }
    	}
    }

    @api
    handleStageChange(stage) {
        if (stage == "Scoping") {
            this.isGating = false;
        } else {
            this.isGating = true;
        }
        //call the child component to update data on stage change
        //this.productid = productId;
        console.log('Inside ChimeQuestionnaie');
        let questionnaireComp = this.template.querySelector('.questionComponent');
        if (questionnaireComp) {
            questionnaireComp.handleStageChange();
        }
        let questionnaireComp2 = this.template.querySelector('.questionComponent2');
        if (questionnaireComp2) {
            questionnaireComp2.handleStageChange();
        }
    }

    @api
    fetchQuestionIds(){
        if(this.iscustomerfacing){
            let qIds = this.template.querySelector('.questionComponent3').fetchQuestionIds();
            return qIds;
        }else{
            let qIds;
            if(this.chimeStage=='Gating'){
            qIds = this.template.querySelector('.questionComponent').fetchQuestionIds();
            }else if(this.chimeStage=='Scoping'){
                qIds = this.template.querySelector('.questionComponent').fetchQuestionIds();
                let qIds2 = this.template.querySelector('.questionComponent2').fetchQuestionIds();
                qIds.push(...qIds2);
            }

        return qIds;
        }
    }

}