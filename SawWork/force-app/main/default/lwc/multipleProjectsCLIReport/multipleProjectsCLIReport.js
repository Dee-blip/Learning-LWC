import { LightningElement, track, wire } from 'lwc';
import getfetchResults from '@salesforce/apex/PSA_CLIProjectReportCls.getfetchResults';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

const DATES = {
    january: { startdate: 'yearval'+'-01-01', endate: 'yearval'+'-01-31'},
    february: { startdate:  'yearval'+'-02-01', endate: 'yearval'+'-02-29'},
    march: { startdate:  'yearval'+'-03-01', endate: 'yearval'+'-03-31'},
    april: { startdate:  'yearval'+'-04-01', endate: 'yearval'+'-04-30'},
    may: { startdate:  'yearval'+'-05-01', endate: 'yearval'+'-05-31'},
    june: { startdate:  'yearval'+'-06-01', endate: 'yearval'+'-06-30'},
    july: { startdate:  'yearval'+'-07-01', endate: 'yearval'+'-07-31'},
    august: { startdate:  'yearval'+'-08-01', endate: 'yearval'+'-08-31'},
    september: { startdate:  'yearval'+'-09-01', endate: 'yearval'+'-09-30'},
    october: { startdate:  'yearval'+'-10-01', endate: 'yearval'+'-10-31'},
    november: { startdate:  'yearval'+'-11-01', endate: 'yearval'+'-11-30'},
    december: { startdate:  'yearval'+'-12-01', endate: 'yearval'+'-12-31'}  
} 

const PREVMONTH = { 
    1 : 'january',
    2 : 'february',
    3 : 'march',
    4 : 'april',
    5 : 'may',
    6 : 'june',
    7 : 'july',
    8 : 'august',
    9 : 'september',
    10 : 'october',
    11 : 'november',
    0 : 'december'
}

export default class MultipleProjectsCLIReport extends NavigationMixin(LightningElement) {

    @track contractData = [];
    @track periodstartdate; 
    @track periodenddate;  
    @track selmonth;
    @track selyear;
    @track value;
    @track yearval;
    //@track flag = false; 

    connectedCallback() {
        var d = new Date();
        var monthnum = d.getMonth();
        var curryear = d.getFullYear();
        var month = PREVMONTH[monthnum];
        this.yearval = curryear+''; 
        this.value = month;
        this.finddates(month,curryear);
    }
   
    @track options = [
        { label: 'January', value: 'january' },
        { label: 'February', value: 'february' },
        { label: 'March', value: 'march' },      
        { label: 'April', value: 'april' },
        { label: 'May', value: 'may' },
        { label: 'June', value: 'june' },  
        { label: 'July', value: 'july' },
        { label: 'August', value: 'august' },
        { label: 'September', value: 'september' },
        { label: 'October', value: 'october' },
        { label: 'November', value: 'november' },
        { label: 'December', value: 'december' }
    ];   

    @track years = [
        { label: '2019', value: '2019' },
        { label: '2020', value: '2020' },
        { label: '2021', value: '2021' }
    ];

    navigateToViewRecordPage(event) {
        var recordIdval = event.target.dataset.value;
 
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { 
                recordId: recordIdval,
                objectApiName: 'PS_Overage_Hours__c',
                actionName: 'view' 
            }, 
        });
    } 
 
    handleExecute(ev){
        this.selmonth = this.template.querySelector(".mnth").value;
        this.selyear = this.template.querySelector(".selyr").value;
        //console.log('month **'+this.selmonth);
        //console.log('year **'+this.selyear);
        this.finddates(this.selmonth,this.selyear); 
    } 
 
    finddates(month,selyrval){
        this.periodstartdate = DATES[month].startdate.replace('yearval', selyrval);
        this.periodenddate = DATES[month].endate.replace('yearval', selyrval);
           
        console.log('sd'+this.periodstartdate);
        console.log('ed'+this.periodenddate);

        getfetchResults({enddate1 : this.periodstartdate, enddate2 : this.periodenddate })
            .then(result => {
                this.contractData = JSON.parse(JSON.stringify(result));
                this.contractData.forEach((el) => {
                    el.approverHoursList.forEach((hrs) => {hrs.url = '/' + hrs.recId;});       
                });
                this.error = undefined;
                console.log('result **'+result);
            }).catch(error=>{
                console.log('error **'+error);
                this.error = error;
                this.contacts = undefined;                
            }) 
    } 
}