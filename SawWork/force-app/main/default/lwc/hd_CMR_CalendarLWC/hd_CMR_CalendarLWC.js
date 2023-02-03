/* eslint-env jquery */
import { LightningElement, wire } from 'lwc';
import getAllListViews from '@salesforce/apex/HD_CMR_ChangeCalendar.getAllListViews';
import getCalCMR from '@salesforce/apex/HD_CMR_ChangeCalendar.getCalCMR';
import getListViewRecords from '@salesforce/apex/HD_CMR_ChangeCalendar.getListViewRecords';
import FullCalendarJS from '@salesforce/resourceUrl/FullCalendarJS';
import HD_CMR_Calendar_Style from '@salesforce/resourceUrl/HD_CMR_Calendar_Style';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import TIMEZONE from '@salesforce/i18n/timeZone';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import HD_moment_timezone from '@salesforce/resourceUrl/HD_moment_timezone';
import HD_moment from '@salesforce/resourceUrl/HD_moment';
import logErrorRecord from '@salesforce/apex/HD_UX_Exception_LoggerCls.logErrorRecord';


export default class Hd_CMR_CalendarLWC extends NavigationMixin(LightningElement) {
    show = false;
    applyFilter = true;
    check = false;
    filterId = '';
    options = [];
    recordFilters = [];
    startCalDate;
    endCalDate;
    currentFilter = {};
    megaOptions = [];
    dummy = [];

    options1 = [];
    options2 = [];
    options3 = [];
    options4 = [];
    options5 = [];

    categoriesColor = [];
    colorMap = {};
    serviceOutages = [];
    showSpinner = false;
    fullCalendarJsInitialised = false;
    changeEvents = [];
    rerender = false;
    calDate;
    defaultDate;
    selectedRecord;
    popoverRecord;
    showPreview = false;
    calendarSize = 12;
    previewSize = 5;

    renderedCallback() {
        if (this.fullCalendarJsInitialised) {
            return;
        }
        this.fullCalendarJsInitialised = true;
      
        Promise.all([
            loadScript(this, HD_moment),
            loadScript(this, HD_moment_timezone),
            loadStyle(this, HD_CMR_Calendar_Style),
            loadStyle(this, FullCalendarJS + '/fullcalendar.min.css'),
            loadScript(this, FullCalendarJS + '/jquery.min.js'),
            loadScript(this, FullCalendarJS + '/fullcalendar.min.js'),

        ])
        .then(() => {
            this.initialize();
        })
        .catch(error => {
            console.log('Hd_CMR_CalendarLWC.renderedCallback : ' + error);
            this.logError('Hd_CMR_CalendarLWC.renderedCallback : ' + JSON.stringify(error));
        })
    }

    initialize() {
        let dt = new Date();
        let stDate = new Date();
        let endDate = new Date();
        
        stDate.setUTCMonth( dt.getUTCMonth() - 3 );
        endDate.setUTCMonth( dt.getUTCMonth() + 3 );
       
        let smonthDigit =  stDate.getUTCMonth() + 1;
        if (smonthDigit <= 9) {
            smonthDigit = '0' + smonthDigit;
        }
        
        let emonthDigit =  endDate.getUTCMonth() + 1;
        if (emonthDigit <= 9) {
            emonthDigit = '0' + emonthDigit;
        }

        this.startCalDate = stDate.getUTCFullYear () + '-' + smonthDigit + '-01';
        this.endCalDate = endDate.getUTCFullYear () + '-' + emonthDigit + '-01';
        this.defaultDate = new Date().toISOString();

        this.clearFilterHelper();
        this.filtersRecord();
    }

    handleValueChange(event){
        this.show = true;
        let action = event.target.dataset.id;
        let params = event.detail;

        if (action === "SPONSOR") {
            this.applyFilterRecords('HD_Sponsor_Name__c',params);
        } else if (action === "LOCATION") {
            this.applyFilterRecords('HD_Facility_Location__c',params);
        } else if (action === "STATUS") {
            this.applyFilterRecords('HD_Change_Status__c',params);
        } else if (action === "OWNER") {
            this.applyFilterRecords('HD_Owner_Name__c',params);
        } else if (action === "CATEGORY") {
            this.applyFilterRecords('BMCServiceDesk__Change_Category__c',params);
        }
    }
    
    filtersRecord() {
        this.showSpinner = true;
        getCalCMR({sDate:this.startCalDate, eDate:this.endCalDate})
            .then(data => {
                for(let changeCategory in data.colorSettings) {
                    /* eslint-disable-next-line */
                    if(data.colorSettings.hasOwnProperty(changeCategory)){
                        let color = {};
                        this.colorMap[changeCategory] = data.colorSettings[changeCategory];
                        color.cat = changeCategory;
                        color.catcolor = 'background:'+ data.colorSettings[changeCategory]+ ';float:left;width:15px;height:15px;margin:5px;border:1px solid';
                        this.categoriesColor.push(color);
                    }
                }
                    
                this.categoriesColor = this.categoriesColor.slice(0, data.changeCategoryRange);
                this.serviceOutages = data.serviceOutages;
                this.recordFilters = data.changeRecords;

                this.applyFilterRecords('',this.dummy);
                this.buildOptionValues();
            })
            .catch(error => {
                console.log('Hd_CMR_CalendarLWC.filtersRecord : ' + error);
                this.logError('Hd_CMR_CalendarLWC.filtersRecord : ' + JSON.stringify(error));
            })
    }

    applyFilterRecords(filterApi,params) {
        let appliedRecordResults = [];

        if(filterApi){
            this.currentFilter[filterApi] = params;
        }
        let filterObject = {};
        for (let property in this.currentFilter) {
            if(this.currentFilter[property]) {
                filterObject[property] = new Set(this.currentFilter[property]);      
            }

        }
        appliedRecordResults = this.recordFilters.filter((item)=> {
            return (filterObject.HD_Sponsor_Name__c.size === 0 || filterObject.HD_Sponsor_Name__c.has(item.HD_Sponsor_Name__c) )&&
            (filterObject.HD_Facility_Location__c.size === 0 || filterObject.HD_Facility_Location__c.has(item.HD_Facility_Location__c)) &&
            (filterObject.HD_Change_Status__c.size === 0 || filterObject.HD_Change_Status__c.has(item.HD_Change_Status__c))&&
            (filterObject.HD_Owner_Name__c.size === 0 || filterObject.HD_Owner_Name__c.has(item.HD_Owner_Name__c))&&
            (filterObject.BMCServiceDesk__Change_Category__c.size === 0 || filterObject.BMCServiceDesk__Change_Category__c.has(item.BMCServiceDesk__Change_Category__c))
        });

        this.filter(appliedRecordResults);
        this.showClearOptions();
    }

    showClearOptions() {
        for (let property in this.currentFilter) {
            if(this.currentFilter[property].length>0){
                this.show = true;
                return;
            }
                
        }
        this.show = false;
    }

    buildOptionValues() {
        var filterApi = new Set(['rating','HD_Sponsor_Name__c','HD_Facility_Location__c','HD_Change_Status__c','HD_Owner_Name__c','BMCServiceDesk__Change_Category__c']);
        var nameOptions = new Set();  
        var megaOptions = {};
        var options = [];
        var apiOptions =[]; 
        var opts;
        var temp = [];
        var property;
        filterApi.forEach((item)=> {megaOptions[item] = new Set();});
        this.recordFilters.forEach((item)=>{nameOptions.add(item.name);
        filterApi.forEach((api)=>{ 
            megaOptions[api].add(item[api])});
        });
        nameOptions.forEach((item)=>{options.push({label:item,value:item});});

        for(property in megaOptions) {
            if(megaOptions[property]) {
                temp = [];
                opts = Array.from(megaOptions[property]);
                /* eslint-disable-next-line */
                opts.forEach((item)=>{ 
                    temp.push({'label':item,'value':item}); 
                });
                apiOptions.push(temp)
            }
		}
        this.megaOptions = apiOptions;
        this.options1 = apiOptions[1];
        this.options2 = apiOptions[2];
        this.options3 = apiOptions[3];
        this.options4 = apiOptions[4];
        this.options5 = apiOptions[5];
    }

    handleChange(event) {
        this.filterId = event.detail.value;
        this.emitFilterConfig();
    }

    @wire(getAllListViews)
    getListViews(result) {
        var optionValues=[];
        if (result.data) {
            result.data.forEach((list)=>{
                var temp = {};
                temp.label = list.Name;
                temp.value = list.Id;
                optionValues.push(temp);
            })
            this.options = optionValues;
        }
    }

    getListViewFiltersRecord() {
        this.showSpinner = true; 
        getListViewRecords({filterId : this.filterId})
            .then(data => {
                this.recordFilters = data;

                this.applyFilterRecords('',this.dummy);
                this.buildOptionValues();
            })
            .catch(error => {
                this.showSpinner = false;
                console.log('Hd_CMR_CalendarLWC.getListViewFiltersRecord : ' + error);
                this.logError('Hd_CMR_CalendarLWC.getListViewFiltersRecord : ' + JSON.stringify(error));
            })
    }

    clearFilters() {
        this.show = false;
        let multiSelectPicklist = this.template.querySelectorAll('c-hd_-multi-select-pick-list');
        if (multiSelectPicklist) {
            multiSelectPicklist.forEach((element) => {
                element.clear();
            });  
        }
        
        this.clearFilterHelper();
        this.filter(this.recordFilters);
    }

    handleApplyListView() {
        this.applyFilter = this.applyFilter?false:true;
        this.check = this.check?false:true;
        this.emitFilterConfig();
    }

    emitFilterConfig() {
        if(this.check && this.filterId !== '') {
            this.getListViewFiltersRecord();
        }
        else if(!this.check) {
            this.filtersRecord();
        }
    }

    createNewCMR() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'BMCServiceDesk__Change_Request__c',
                actionName: 'new'
            }
        });
    }

    createDefaultCMR(dt) {
        var startdate = '';
        var sdate =  dt.toISOString();
        startdate = sdate;
        if (sdate.split('T').length === 1){
            startdate += "T00:00:00";
        }
        startdate += "Z" ;
        const defaultValues = encodeDefaultFieldValues({
            HD_Change_Status__c: 'OPENED',
            BMCServiceDesk__Scheduled_Start_Date__c: startdate,
        });
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'BMCServiceDesk__Change_Request__c',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: defaultValues 
            }
        });        
    }

    handleEventClick(event) {
        this.selectedRecord = event.record;
        this.showPreview = true;
        this.calendarSize = 7;
    }

    onClosePreview() {
        this.calendarSize = 12;
        this.showPreview = false;
    }

    //Transform records into event format
    transformToFullCalendarFormat(events) {
        var eventArr = [];

        for(let i = 0; i < events.length ; i++ ) {
            let clr = this.colorMap[events[i].BMCServiceDesk__Change_Category__c];
            eventArr.push({
                id : events[i].Id,
                start : moment.tz(events[i].BMCServiceDesk__Scheduled_Start_Date__c, TIMEZONE), // eslint-disable-line
                end : moment.tz(events[i].BMCServiceDesk__Scheduled_End_Date__c, TIMEZONE), // eslint-disable-line
                title : events[i].Change_Summary__c!=null ? events[i].Change_Summary__c.slice(0,30):'',
                color : clr,
                record :events[i],
                timezoneParam :TIMEZONE
            });
        }

        return eventArr;
    }

    //Position the popover on mouseover
    positionPopover(record,event) {
        this.popoverRecord = record;
        let ele = this.template.querySelector('[data-id="popover"]');
        if(ele) {
            ele.style.left = event.pageX < 450 ? (event.pageX + 100) + "px" : (event.pageX - 400) + "px";
            ele.style.top = event.pageY > 620 ? (event.pageY - 650) + "px" : (event.pageY - 320) + "px";
            ele.classList.remove('slds-hide');
        }
    }

    //Initialize the calendar 
    initialiseFullCalendarJs() {
        const ele = this.template.querySelector('div.fullcalendarjs');
        let self = this;
    
        $(ele).fullCalendar({
            header: {
                left: '',
                center: 'title',
                right: 'prev,next today month,agendaWeek,agendaDay'
            },
            buttonText: {      
                today:    'Today',
                month:    'Month',
                week:     'Week',
                day:      'Day',
            },
            height: 670,
            displayEventTime: false,
            defaultDate: new Date(),
            allDaySlot: false,
            slotEventOverlap: false,
            nowIndicator:true,
            navLinks: true, 
            editable: false,
            timezone: TIMEZONE,
            eventLimit: true, 
            //eventLimitClick: "day",
            eventClick: function(event) {
                self.handleEventClick(event);
            },
            eventMouseover: function(data, event){
                self.positionPopover(data.record,event);
            },
            eventMouseout: function() {
                self.template.querySelector('[data-id="popover"]').classList.add('slds-hide');
            },
            dayRender: function(date, cell) {
                var dt = new Date(date); 
                for(let i= 0; i < self.serviceOutages.length; i++ ) {
                                            
                    let blkout = self.serviceOutages[i];
                    let stdate =  new Date(blkout.BMCServiceDesk__Start_Date__c);
                    let edate =  new Date(blkout.BMCServiceDesk__End_Date__c);
                        
                    if(dt >= stdate && dt <= edate ){
                        if(blkout.BMCServiceDesk__Blackout__c === true){
                            cell.css("background","#ABB2B9");
                            cell.attr('title', 'Blackout Priod :'+blkout.Name);
                        }
                        else if(blkout.Service_Outage_Type__c !== ''){
                            cell.css("background","#D1F2EB");
                            cell.attr('title', blkout.Service_Outage_Type__c+':'+blkout.Name);
                        }
                    }
                }
                cell.bind('dblclick',function() {
                    self.createDefaultCMR(date);
                })
            },
            events: this.changeEvents
        });

        const prevButton = this.template.querySelector('.fc-prev-button');
        $(prevButton).click(function() {
            self.compareDateRange();
            let vw = $(ele).fullCalendar('getView');
            if(vw.name === 'agendaDay' || vw.name === "agendaWeek") {
                self.backgroundForBlackout();
            }
        });

        const nextButton = this.template.querySelector('.fc-next-button');
        $(nextButton).click(function() {
            self.compareDateRange();
            let vw = $(ele).fullCalendar('getView');
            if(vw.name === 'agendaDay' || vw.name === "agendaWeek") {
                self.backgroundForBlackout();
            }
        });

        const todayButton = this.template.querySelector('.fc-today-button');
        $(todayButton).click(function() {
            self.compareDateRange();
            let vw = $(ele).fullCalendar('getView');
            if(vw.name === 'agendaDay' || vw.name === "agendaWeek") {
                self.backgroundForBlackout();
            }
        });

        const weekButton = this.template.querySelector('.fc-agendaWeek-button');
        $(weekButton).click(function() {
            self.backgroundForBlackout();
        });

        const dayButton = this.template.querySelector('.fc-agendaDay-button');
        $(dayButton).click(function() {
            self.backgroundForBlackout();
        });

    }

    //Show filtered events on the calendar
    filter(resp) {
        this.changeEvents = this.transformToFullCalendarFormat(resp);
        if(!this.rerender){
            this.rerender = true;
            this.initialiseFullCalendarJs();
            this.template.querySelector('.fc-center').style.paddingLeft = "270px";
            this.template.querySelector('.fc-center h2').style.fontSize = "26px";
        }
        else {
            const ele = this.template.querySelector('div.fullcalendarjs');
            $(ele).fullCalendar('removeEvents');
            $(ele).fullCalendar('addEventSource', this.changeEvents);
            $(ele).fullCalendar('rerenderEvents');
        }
        this.showSpinner = false;
    }

    clearFilterHelper() {
        this.currentFilter.HD_Sponsor_Name__c = new Set();
        this.currentFilter.HD_Facility_Location__c = new Set();
        this.currentFilter.HD_Change_Status__c = new Set();
        this.currentFilter.BMCServiceDesk__Initiator_ID__c = new Set();
        this.currentFilter.HD_Owner_Name__c = new Set();
        this.currentFilter.BMCServiceDesk__Change_Category__c = new Set();
    }

    //Get date in proper format for calendar
    addMonthstoDate(dt,monthnumber) { 
        var newDate = new Date(dt);
        newDate.setMonth( newDate.getUTCMonth() + monthnumber );
 
        let smonthDigit =  newDate.getUTCMonth() + 1;
        if (smonthDigit <= 9) {
            smonthDigit = '0' + smonthDigit;
        }
         
        let dayDigit = newDate.getDate();
        if(dayDigit <= 9){
            dayDigit = '0' + dayDigit;
        }

        //return  newDate.getUTCFullYear() + "-" + smonthDigit + "-" + "01";
        return `${newDate.getUTCFullYear()}-${smonthDigit}-01`;
    }

    //Set new date range
    compareDateRange() { 
        const ele = this.template.querySelector('div.fullcalendarjs');
        var moment = $(ele).fullCalendar('getDate');
        var thisDate = new Date(moment);
         
        this.calDate = this.addMonthstoDate(thisDate,0)
        if(this.calDate >= this.endCalDate || this.calDate <= this.startCalDate){
            this.endCalDate = this.addMonthstoDate(this.calDate, 3);
            this.startCalDate = this.addMonthstoDate(this.calDate, -3);
            this.emitFilterConfig();
        } 
    }

    navigateToDate(event) {
       if(event.target.value) {
            let dt = moment(event.target.value); // eslint-disable-line
            const ele = this.template.querySelector('div.fullcalendarjs');
            $(ele).fullCalendar('gotoDate', dt);
            this.compareDateRange(); 
            let vw = $(ele).fullCalendar('getView');
            if(vw.name === 'agendaDay' || vw.name === "agendaWeek") {
                this.backgroundForBlackout();
            }
       }
    }

    //Set service outage background in week and day views
    backgroundForBlackout() {
        const ele = this.template.querySelector('div.fullcalendarjs');
        var today = new Date();
        var cmp_sdate = today;
        var cmp_edate = today;
       
        var tds = ele.querySelectorAll('td');
        var datetds = [];   
        for(let i = 0; i < tds.length; i++) {
            let ds = tds[i].dataset;
          
            if(ds) {
                datetds.push(tds[i]);
                let dst = new Date(ds.date);
                if( dst < cmp_sdate){
                    cmp_sdate = dst;
                }
                if( dst > cmp_edate){
                    cmp_edate = dst;
                }    
            }
        }

        let matchSO = [];
        let sdate;
        let edate;
        for(let i= 0; i < this.serviceOutages.length; i++ ) {
            let so = this.serviceOutages[i];
            sdate = new Date(so.BMCServiceDesk__Start_Date__c);
            edate = new Date(so.BMCServiceDesk__End_Date__c);
            if(cmp_sdate <= edate && cmp_edate >= sdate) {   
                matchSO.push(so);
            }
        }      
    
        if(matchSO.length > 0) {
            for(let k = 0; k < datetds.length; k++ ) {  
                let el = datetds[k];
                if(!el.dataset.date){
                    continue;
                }
                let dt = new Date(el.dataset.date);
                for(let l=0; l < matchSO.length; l++) {
                    let so = matchSO[l];
                    sdate = new Date(so.BMCServiceDesk__Start_Date__c);
                    edate = new Date(so.BMCServiceDesk__End_Date__c);
                  
                     if(dt >= sdate && dt <= edate) {
                        if(so.BMCServiceDesk__Blackout__c === true){
                                el.style.backgroundColor = "#ABB2B9";
                                el.title = 'Blackout Priod :'+so.Name+ '  From '+sdate+ ' To '+edate;

                            }
                        else if(so.Service_Outage_Type__c !== ''){
                            el.style.backgroundColor = "#D1F2EB";
                            el.title =  so.Service_Outage_Type__c+':'+so.Name + ' From '+sdate+ ' To '+edate;     
                        }
                    }
                }
            }
        }
    }

    logError(error) {
        logErrorRecord({
            ErrorMsg: error,
            Stacktrace: null,
            IncidentId: this.recordId
        });
    }
}