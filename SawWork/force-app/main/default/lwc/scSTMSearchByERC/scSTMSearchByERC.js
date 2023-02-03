import { LightningElement, track } from 'lwc';
import searchByERC from '@salesforce/apex/SC_STM_HomePageController.getDetailsFromERC';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class scSTMSearchByERC extends LightningElement {
    @track teamColumns = [
        {
            label: 'Team Name',
            fieldName: 'teamName',
            type: 'text',
          },
          {
              label: 'Team Type',
              fieldName: 'teamType',
              type: 'text',
              cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}
          },
          {
              label: '# Accounts',
              fieldName: 'noAccounts',
              type: 'text'
          },
    ];
    @track accColumns = [
        {
            label: 'Team Account',
            fieldName: 'Team_Account_URL__c',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Team_Account_Name__c' },
                target: "_blank"
            }
        },
        {
            label: 'AKAM Account ID',
            fieldName: 'Team_AKAM_Account_ID__c',
            type: 'text',
            cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}
        },
    ]

    @track memColumns = [
        {
            label: 'Team Member',
            fieldName: 'Team_Member_URL__c',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Team_Member_Name__c' },
                target: "_blank"
            },
            cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}
        },
        {
            label: 'Role',
            fieldName: 'Role__c',
            type: 'text'
        },
        {
            label: 'Support Team Skill',
            fieldName: 'SC_STM_Support_Team_Skill__c',
            type: 'text',
            cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}
        },
    ]
    @track teamData;
    @track accData;
    @track memData;
    @track errorMsg = '';
    @track loadSpinner = false;
    strSearchERC = '';
    

    handleERCChange(event) {
        this.strSearchERC = event.detail.value;
    }

    handleSearch() {
        this.loadSpinner = true;
        if(!this.strSearchERC) {
            this.showToast('Please enter ERC to search!', 'error', 'dismissable');
            this.teamData = undefined;
            this.accData = undefined;
            this.memData = undefined;
            this.loadSpinner = false;
            return;
        }

        searchByERC({ERC : this.strSearchERC})
        .then(result => {
            console.log('all' + result);
            result = JSON.parse(result);
            
            this.teamData = result.supportTeam == null ? undefined : result.supportTeam;
            this.accData = result.teamAccounts == null ? undefined : result.teamAccounts;
            this.memData = result.teamMembers == null ? undefined : result.teamMembers;
            if(this.teamData == undefined){
                this.showToast('Enter a valid ERC!', 'error', 'dismissable');
                this.loadSpinner = false;
            }
            this.loadSpinner = false;
        })
        .catch(error => {
            this.teamData = undefined;
            this.accData = undefined;
            this.memData = undefined;
            console.log('error =====> '+JSON.stringify(error));
            if(error) {
                this.showToast(error.body.message, 'error', 'dismissable');
                this.loadSpinner = false;
            }
        }) 
    }

    showToast(message,variant,mode) {
        const evt = new ShowToastEvent({
            
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }

    keycheck(event){
        if(event.which == 13){
            this.handleSearch();
        }
      }  

}