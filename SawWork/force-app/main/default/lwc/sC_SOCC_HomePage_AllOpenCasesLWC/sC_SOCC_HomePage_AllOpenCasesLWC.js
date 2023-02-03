/** @Date		    :	April 5 2020
* @Author		: 	Sumukh SS 
* @Description	:	Orginal ESESP-2198 : 
Migrating SOCCDash from Aura to LWC. Rebuilding the entire codebase to make JS calculation time <5ms across the board.
* WARNING: Please consult author / related team members before comitting any changes. SOCCDash LWC is heavily customized since it is shown using Lightning Out
Standard LWC styles do not work in lightning out such as toast,lightning message etc.
VF Page : SC_SOCC_HomePage_LCOut_VF
Aura Dependency : SC_SOCC_LightningApp

-------------------------History-------------------
Date                    Author              Changes

March 23 2021           Tejaswini           Few minor changes on dashboard
Nov 17 2021             Jay                 ESESP-6330 | Added filter to get US Fed Accounts

*/

import { LightningElement, wire, track } from 'lwc';
import getAllData from '@salesforce/apex/SC_SOCC_Lightning_HomePage.getSocHomeTask';
import getGeoValues from '@salesforce/apex/SC_SOCC_Lightning_HomePage.getSavedGeo';
import savegeofilters from '@salesforce/apex/SC_SOCC_Lightning_HomePage.saveSelectedFilters';
import recordtype from '@salesforce/apex/SC_SOCC_Lightning_HomePage.getRecordTypeID';

const actions = [
    

];
const columns = [{
    label: 'AKAM Case ID',
    fieldName: 'AkamCaseIDURL',
    type: 'url', typeAttributes: { label: { fieldName: 'AkamCaseID' }, target: '_blank' },
    cellAttributes: { class: { fieldName: 'CaseColor' } }
},
{
    label: 'Account',
    fieldName: 'AccountName',
    type: 'text'
},
{
    label: 'Policy Domain',
    fieldName: 'PolicyDomainURL',
    type: 'url', type: 'url', typeAttributes: { label: { fieldName: 'PolicyDomain' }, target: '_blank' }

},
{
    label: 'Severity',
    fieldName: 'Severity',
    type: 'text',
    initialWidth: '50'
},
{
    label: 'Geography',
    fieldName: 'Geo',
    type: 'text',
},
{
    label: 'Subject',
    fieldName: 'Subject',
    type: 'text'
},
{
    label: 'Problem',
    fieldName: 'Problem',
    type: 'text'
},
{
    label: 'Task Owner',
    fieldName: 'TaskURL',
    type: 'url', typeAttributes: { label: { fieldName: 'TaskOwner' }, target: '_blank' }
},
{
    label: 'Due In',
    fieldName: 'TaskDueDateinMinutes',
    type: 'text',
    cellAttributes: { class: { fieldName: 'TimeColor' } }
},
{
    label: 'Task Status',
    fieldName: 'TaskStatus',
    type: 'text'
},
{
    label: 'Task Type',
    fieldName: 'Tasktype',
    type: 'text'
},
{
    label: 'Last Update By?',
    fieldName: 'CaseLastUpdateBy',
    type: 'text'
},
{
    label: 'Last Update',
    fieldName: 'LastUpdateTimeinMinutes',
    type: 'text'
},
{
    type: 'action',
    typeAttributes: { rowActions: [{ label: 'Edit Case inline', name: 'Edit' },
    { label: 'Copy AKAM Case ID', name: 'Copy AKAM Case ID' },
    { label: 'Copy Case URL', name: 'Copy Case URL' },
    { label: 'Open in Classic', name: 'Open in Classic' }], menuAlignment: 'right' }
}
];

export default class SC_SOCC_HomePage_AllOpenCasesLWC extends LightningElement {
    //Unsavable filter section logic
    @track isOpen = false;
    @track SOCCPremiumvalue = 'All';
    @track checkboxvalue = ['1', '2', '3'];
    @track Priorityvalue = 'All';
    @track CaseOwnervalue = 'All';
    @track SearchTypevalue = 'AKAM_Case_ID__c';
    //Geography Values
    @track Americas = false;
    @track AP = false;
    @track Japan = false;
    @track EMEA = false;
    @track Others = false;
    //Mini dashboard count
    @track TotalCount = 0;
    @track OverdueCount = 0;
    @track YellowTasksCount = 0;
    @track PurpleTasksCount = 0;
    @track WhiteTasksCount = 0;
    @track ApprovalCount = 0;
    @track showspinner = true;
    @track ToastMessage;
    //Variable to track poll ID
    PollID;

    @track paginationRange = [];
    @track currentpage;
    @track columns = columns;
    @track error;
    @track SlicedDatalist;
    offset = 1;
    CompleteDatalist;
    paginationNumbers;

    //Tracking attributes for edit form
    @track bShowModal = false;
    @track currentRecordId;

    get SOCCPremiumoptions() {
        return [
            { label: 'All', value: 'All' },
            { label: 'True', value: 'True' },
            { label: 'False', value: 'False' }
        ];
    }
    handleSOCCChange(e) {
        this.SOCCPremiumvalue = e.detail.value;
    }
    handlepriorityChange(e) {
        this.Priorityvalue = e.detail.value;
    }
    handleCaseOwnerChange(e) {
        this.CaseOwnervalue = e.detail.value;
    }
    handlecheckboxChange(e) {
        this.checkboxvalue = e.detail.value;
    }
    handleSearchChange(e) {
        this.SearchTypevalue = e.detail.value;
    }

    get Checkboxoptions() {
        return [
            { label: '1', value: '1' },
            { label: '2', value: '2' },
            { label: '3', value: '3' }
        ];
    }
    get CaseOwneroptions() {
        return [
            { label: 'All', value: 'All' },
            { label: 'SOC Technicians Queue', value: 'SOC Technicians Queue' },
            { label: 'SOC Specialists Queue', value: 'SOC Specialists Queue' },
            { label: 'SOC Managers Queue', value: 'SOC Managers Queue' },
            { label: 'SOC Netops Queue', value: 'SOC Netops Queue' }

        ];
    }
    get Priorityoptions() {
        return [
            { label: 'All', value: 'All' },
            { label: 'Hot Customer', value: 'Hot Customer' },
            { label: 'White Glove Treatment', value: 'White Glove Treatment' },
            { label: 'High Alert Customer', value: 'High Alert Customer' },
            { label: 'General/Others', value: 'General/Others' }
        ];
    }

    get SearchTypeoptions() {
        return [
            { label: 'AKAM Case ID', value: 'AKAM_Case_ID__c' },
            { label: 'Account Name', value: 'Account.Name' },
            { label: 'Problem', value: 'Problem__c' }
        ];
    }


    handleClick(event) {
        var isOpen = this.isOpen;
        this.isOpen = !isOpen;
    }

    GeoAdd(event)
    {
         //var t0 = performance.now();
        let allgeos = this.template.querySelectorAll('.geo');
        var selectedgeos = [];
        for (var i = 0; i < allgeos.length; i++) {
            if (allgeos[i].checked)
                selectedgeos.push(allgeos[i].value);
        }

        var geos = selectedgeos.toString();
        var n = geos.search("Americas"); if (n != -1) this.Americas = true; else this.Americas = false;
        n = geos.search("AP"); if (n != -1) this.AP = true; else this.AP = false;
        n = geos.search("Japan"); if (n != -1) this.Japan = true; else this.Japan = false;
        n = geos.search("EMEA"); if (n != -1) this.EMEA = true; else this.EMEA = false;
        n = geos.search("Others"); if (n != -1) this.Others = true; else this.Others = false;
        //var t1 = performance.now();
        //console.log("------------>Geo took " + (t1 - t0) + " milliseconds to execute.")

    }

    saveFilters(event) {
        var errorsnackbar;
        let allgeos = this.template.querySelectorAll('.geo');
        var selectedgeos = [];
        for (var i = 0; i < allgeos.length; i++) {
            if (allgeos[i].checked)
                selectedgeos.push(allgeos[i].value);
        }
        let usedheap;
        let chromeAgent = navigator.userAgent.indexOf("Chrome") > -1;       
        let firefoxAgent = navigator.userAgent.indexOf("Firefox") > -1; 
        let safariAgent = navigator.userAgent.indexOf("Safari") > -1; 
        // Discard Safari since it also matches Chrome 
        if ((chromeAgent) && (safariAgent)) safariAgent = false; 
        
        if(chromeAgent)
        {
            usedheap= Math.ceil(window.performance.memory.usedJSHeapSize/1000000);
        }
        else
        {
            if(firefoxAgent) usedheap='Firefox';
            if(safariAgent) usedheap='Safari';
        }
        if(selectedgeos.length>0){
        this.showspinner=true;
        let accountTypesToShow = this._accountTypeOptions.filter(option => option.checked).map(option => option.value).join(",");
        savegeofilters({
            SelectedGeoFromUser: selectedgeos,
            SOCCDashUserLog:usedheap,
            accountTypesToShow
        })
            .then(result => {
                this.ToastMessage = 'Filters saved! Refreshing data..'
                var x = this.template.querySelector(".snackbar");
                x.style.visibility = "visible";
                setTimeout(function () { x.style.visibility = x.style.visibility.replace("visible", "hidden"); }, 2000);
                this.ClearPollerAndRefreshTable();

            })
            .catch(error => {
                console.log('error' + JSON.stringify(error));
            });
        }
        else{
            this.ToastMessage = 'Please select atleast one Geography Value..'
            errorsnackbar = this.template.querySelector(".errorbar");
            errorsnackbar.style.visibility = "visible";
            setTimeout(function () { errorsnackbar.style.visibility = errorsnackbar.style.visibility.replace("visible", "hidden"); },3000);
            
            //this.ClearPollerAndRefreshTable();
            
        }
    }


    async connectedCallback() {
        try{
            let response = await getGeoValues();
            if (response){
                let {geographies:geos,accountTypes} = response;

                this.Americas = geos.includes("Americas");
                this.AP = geos.includes("AP");
                this.Japan = geos.includes("Japan");
                this.EMEA = geos.includes("EMEA");
                this.Others = geos.includes("Others");

                if (Array.isArray(accountTypes) && accountTypes.length > 0){
                    this._accountTypeOptions.forEach(option => {
                        option.checked = accountTypes.includes(option.value);
                    });
                }

                window.addEventListener("visibilitychange", this.listenForMessage.bind(this));
                this.getallcasesdata('All', 'All', 'All', '[1,2,3]', null, null);

                this.PollID = setInterval(() => {
                    console.log('running poller : '+this.PollID);
                    this.refreshTable();
                }, 70000);
                console.log('poller ID : ' + this.PollID);

            }
        }catch (e) {
            this.error = e;
            console.log(e);
        }

    }

    resetallfilters() {
    this.showspinner = true;
    this.SOCCPremiumvalue = 'All';
    this.checkboxvalue = ['1', '2', '3'];
    this.Priorityvalue = 'All';
    this.CaseOwnervalue = 'All';
    this.SearchTypevalue = 'AKAM_Case_ID__c';
    this.getallcasesdata('All', 'All', 'All', '[1,2,3]', null, null);
    this.template.querySelector(".inputCmp").value = null;
    }

    listenForMessage(message) {
        if (document.hidden || document.webkitHidden || document.msHidden || document.mozHidden) {
            console.log('Clearing poller as user left!');
            window.clearInterval(this.PollID);
         }
        else 
        {
            console.log('User came back!');
            this.ClearPollerAndRefreshTable();
            
        }
    }
   
    ClearPollerAndRefreshTable(event) {
        window.clearInterval(this.PollID);
        this.PollID = setInterval(() => {
            console.log('running poller : '+this.PollID);
            this.refreshTable();
        }, 70000);
        console.log('poller ID : ' + this.PollID);
        if(typeof(event)!='undefined') {this.showspinner=true;}
        this.refreshTable();

    }
    refreshTable() {

        var inputCmp = this.template.querySelector(".inputCmp");
        if (inputCmp === null) {
            var value = null
        }
        else {
            var value = inputCmp.value;
        }
        this.getallcasesdata(this.Priorityvalue, this.CaseOwnervalue, this.SOCCPremiumvalue, this.checkboxvalue, value, this.SearchTypevalue);
     
    }

    getallcasesdata(Priority, owner, premium, Severity, searchval, searcht) {

        getAllData({
            PriorityFilter: Priority,
            CaseOwnerFilter: owner,
            premiumFilter: premium,
            SeverityFilter: Severity,
            searchvalue: searchval,
            searchtype: searcht
        })
            .then(result => {
                var t0 = performance.now();
                this.CompleteDatalist = result.FinalList;
                this.TotalCount = result.TotalCount;
                this.OverdueCount = result.OverdueCount;
                this.YellowTasksCount = result.YellowCount;
                this.PurpleTasksCount = result.PurpleCount;
                this.WhiteTasksCount = result.WhiteCount;
                this.ApprovalCount = result.ApprovalCount;
                
                this.paginationNumbers = Math.ceil(this.TotalCount / 100);
                if(this.offset>this.paginationNumbers) this.offset=1;
                
                this.currentpage=this.offset+'/'+this.paginationNumbers;
                this.paginationRange = [];
                for (var i = 1; i <= this.paginationNumbers; i++) {
                    this.paginationRange.push(i);
                }
                this.SlicedDatalist = result.FinalList.slice((this.offset - 1) * 100, this.offset * 100);
                
                this.showspinner = false;

                var t1 = performance.now();
                console.log("------------>Homeload took " + (t1 - t0) + " milliseconds to execute" );

            })
            .catch(error => {
                this.error = error;
                console.log(error);
            });
    }

    //Pagination logic
    handlePaginationClick(event) {
       var t0 = performance.now();
        let page = event.target.dataset.item;
        this.offset=page;
        this.SlicedDatalist = this.CompleteDatalist.slice((this.offset - 1) * 100, this.offset * 100);
        this.currentpage=this.offset+'/'+this.paginationNumbers;

        var t1 = performance.now();
        console.log("------------>Pagination took " + (t1 - t0) + " milliseconds to execute.")
    }

    @track recTypeIdSOCC='';

    handleRowActions(event) {
        if (event.detail.action.name === 'Edit') {
            if(this.recTypeIdSOCC==='')
            {
                recordtype({
                })
                .then(result => {
                    this.recTypeIdSOCC=result;
                }).catch(error => {
                    this.error = error;
                    console.log(error);
                });
            }
            let row = event.detail.row.AkamCaseIDURL;
            row = row.substring(1);
            this.bShowModal = true;
            this.currentRecordId = row;

        }
        else if (event.detail.action.name === 'Copy Case URL') {

            let row = event.detail.row.AkamCaseIDURL;
            row=location.hostname+row;
            var hiddenInput = document.createElement("input");
            hiddenInput.setAttribute("value", row);
            document.body.appendChild(hiddenInput);
            hiddenInput.select();
            document.execCommand("copy");
            document.body.removeChild(hiddenInput);
            this.ToastMessage = 'Copied link to case!'
            var x = this.template.querySelector(".snackbar");
            x.style.visibility = "visible";
            setTimeout(function () { x.style.visibility = x.style.visibility.replace("visible", "hidden"); }, 3000);

        }
        else if (event.detail.action.name === 'Copy AKAM Case ID') {
            let row = event.detail.row.AkamCaseID+' '+event.detail.row.Subject;
            var hiddenInput = document.createElement("input");
            hiddenInput.setAttribute("value", row);
            document.body.appendChild(hiddenInput);
            hiddenInput.select();
            document.execCommand("copy");
            document.body.removeChild(hiddenInput);

            this.ToastMessage = 'Copied AKAM Case ID and subject!'
            var x = this.template.querySelector(".snackbar");
            x.style.visibility = "visible";
            setTimeout(function () { x.style.visibility = x.style.visibility.replace("visible", "hidden"); }, 3000);
        }
        else if(event.detail.action.name === 'Open in Classic')
        {
            var ID = event.detail.row.AkamCaseIDURL;
            ID = ID.substring(1);
            var classicurlpara='/console#%2F'+ID;
            window.open(classicurlpara,'_blank');
        }
    }
    closeModal(event) {
        this.bShowModal = false;
    }
    handleSubmit(event)
    {
        this.showspinner = true;
    }
    handleError(event)
    {
        this.showspinner = false;
    }
    handleSuccess(event)
    {
        this.showspinner = false;
        this.bShowModal = false;
        this.ToastMessage = 'Record successfully saved!'
        var x = this.template.querySelector(".snackbar");
        x.style.visibility = "visible";
        setTimeout(function () { x.style.visibility = x.style.visibility.replace("visible", "hidden"); }, 3000);
  
    }
    openNewCase(event)
    {
        window.open('/one/one.app#/sObject/Case/new','_blank');          
    }

    //Notification Center Code 

    @track notificationlist=[];
    @track shownavbar=false;
    getNavRecords(event)
    {
        //var t0 = performance.now();
        let color = event.target.value;
        var filteredlist=[];
        for (var i = 0; i < this.CompleteDatalist.length; i++) 
        {
            if(this.CompleteDatalist[i].NotificationCenterType===color)
            if(color==='runbook')
            {  var x= {AkamCaseID:this.CompleteDatalist[i].AkamCaseID, AkamCaseIDURL:this.CompleteDatalist[i].AkamCaseIDURL,Body:'Case '+this.CompleteDatalist[i].AkamCaseID+' has pending runbook approvals!'};
            filteredlist.push(x);
            }
            else if(color==='white')
            { var x= {AkamCaseID:this.CompleteDatalist[i].AkamCaseID, AkamCaseIDURL:this.CompleteDatalist[i].AkamCaseIDURL,Body:'Case '+this.CompleteDatalist[i].AkamCaseID+' is unassigned!'};
            filteredlist.push(x);
            }
            else if(color==='yellow')
            {var x= {AkamCaseID:this.CompleteDatalist[i].AkamCaseID, AkamCaseIDURL:this.CompleteDatalist[i].AkamCaseIDURL,Body:'Case '+this.CompleteDatalist[i].AkamCaseID+' has an email update!'};
            filteredlist.push(x);
            }
            else if(color==='purple')
            {var x= {AkamCaseID:this.CompleteDatalist[i].AkamCaseID, AkamCaseIDURL:this.CompleteDatalist[i].AkamCaseIDURL,Body:'Case '+this.CompleteDatalist[i].AkamCaseID+' has no / only completed tasks!'};
            filteredlist.push(x);
            }
            else if(color==='overdue')
            {
                var x= {AkamCaseID:this.CompleteDatalist[i].AkamCaseID, AkamCaseIDURL:this.CompleteDatalist[i].TaskURL, Body:'Task '+this.CompleteDatalist[i].Tasktype+' of '+this.CompleteDatalist[i].AkamCaseID+'  has missed its due date since '+this.CompleteDatalist[i].TaskDueDateinMinutes};
            filteredlist.push(x);
            }
         }
        
        this.notificationlist=filteredlist;
        var x = this.template.querySelector(".sidenav");
        x.style.width = "270px";
       // var t1 = performance.now();
        //console.log("------------>Refresh values took " + (t1 - t0) + " milliseconds to execute.")
        
    }

    closeNav(event)
    {
        var x = this.template.querySelector(".sidenav");
        x.style.width = "0px";
    }

    openNewTab(event)
    {
        window.open(event.target.value,'_blank');          
    }

    _accountTypeOptions = [
        {value: "excludeUSFed", label: "Exclude Federal", checked: false}
    ]

    onAccountTypeSelect(){
        let accountTypeCheckboxes = this.template.querySelectorAll('[data-elem-type="account-type"]');
        let index = {};
        for (const checkbox of accountTypeCheckboxes) {
            index[checkbox.name] = checkbox.checked;
        }
        this._accountTypeOptions = [...this._accountTypeOptions.map(option =>{
            option.checked = index[option.value];
            return option;
        })]
    }

    get accountTypeOptions(){
        return this._accountTypeOptions;
    }
    
}