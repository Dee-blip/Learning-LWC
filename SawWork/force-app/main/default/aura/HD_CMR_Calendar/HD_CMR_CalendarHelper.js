({
    colorMap: {},
	
   loadDataToCalendar :function(component,data,helper,serviceoutages){ 
      
            var ele = $('#calendar');

            $(ele).fullCalendar({
                header: {
                            left: 'prev,next today ',
                            center: 'title',
                            right: 'month,agendaWeek,agendaDay'
                        },
                buttonText: {
                    
                      today:    'Today',
                      month:    'Month',
                      week:     'Week',
                      day:      'Day',

                },
                
                viewRender: function(view) {
                var title = view.title;
                $('.fc-center').find('h2').html(title);
              },
                displayEventTime: false,
                defaultDate: new Date(),
                allDaySlot: false,
                slotEventOverlap: false,
                nowIndicator:true,
                dayClick: dayClickCallback,
                editable: false,
                eventLimit: true, 
                eventClick: function( event, element, view ) {
                                quickCMR(event);
                             },
                fixedWeekCount:false,
                
                timezone: $A.get("$Locale.timezone"),
                
                dayRender: function( date,cell,component){
                
                                    var dt = new Date(date); 
                                    for(var i= 0; i < serviceoutages.length; i++ ){
                                        
                                             let blkout = serviceoutages[i];
                                             var stdate =  new Date(blkout.BMCServiceDesk__Start_Date__c);
                                             var edate =  new Date(blkout.BMCServiceDesk__End_Date__c);
                                             
                                            if(dt >= stdate && dt <= edate ){
                                                if(blkout.BMCServiceDesk__Blackout__c == true){
                                                    cell.css("background","#ABB2B9");
                                                    cell.attr('title', 'Blackout Priod :'+blkout.Name);
  
                                                }
                                                else if(blkout.Service_Outage_Type__c != ''){
                                                   cell.css("background","#D1F2EB");
                                                   cell.attr('title', blkout.Service_Outage_Type__c+':'+blkout.Name);
                                                    
                                                }
                                                
                                            }
                                    }
                                    
                                },
                eventMouseover: function (data, event, view){

                                    component.set("v.ch",data.record);
                                    //$(".tooltipcustom").css({top: event.pageY, left: event.pageX, position:'absolute'});
                                    
                                    var mousex = event.pageX ; //Get X coordinates
                                    var mousey = event.pageY ; //Get Y coordinates
                    				var tooltipWidth = $('.tooltipcustom').outerWidth();
                    				var tooltipHeight = $('.tooltipcustom').outerHeight();
                    				var calendarHeight = $(window).width()-100;
                    				var calendarWidth = $(window).height()-40;
                    				var top = mousey;
                    				var left = mousex;
                                    
                                      if((mousey+tooltipHeight+100)>=calendarHeight)
                                       {
                                        $('.tooltipcustom')
                                        top= mousey-tooltipHeight-50;
                                    
                                       }
                                       if((mousex+tooltipWidth+40)>=calendarWidth)
                                       {
                                          $('.tooltipcustom')
                                              left= mousex-tooltipWidth-20;
                                    
                                       }  
                                    
                                   
                                  $('.tooltipcustom').css({ top: top, left: left });
                   					$(".tooltipcustom").css({position:'absolute'});
                    				$('.tooltipcustom').css('display','block');
                                },
                
                eventMouseout: function (data, event, view) {
                                $(this).css('z-index', 8);
                                component.set("v.ch",null);
                               },
                events: data, 
                
            });

       var slotDate;
       
   
        var dateCmp = document.getElementById("dateId");
        var pos = $(".fc-today-button").position();
      
       dateCmp.style.position = "absolute";
       var posLeft = pos.left+20+$(".fc-today-button").outerWidth();
       var x = $("#dateId").outerHeight();

       var y = $("lightning-datepicker").outerHeight(true);
       
       var posTop = pos.top-20;
       dateCmp.style.left = posLeft+"px";
       dateCmp.style.top = posTop+"px";
       var dateComponent = component.find("dateId");
      $A.util.removeClass(dateComponent, 'slds-hide');
       
       
       function quickCMR(ev){ 
          
		var quick_space = component.find('auraquickCMR'); 
         $A.util.removeClass(quick_space, "slds-hide");
         var showcmr = $A.get("e.c:HD_CMR_UpdateCMRID");
         showcmr.setParams({"changecmr":ev.record}).fire();
           
       }
             
       
       
    function dayClickCallback(date){
        slotDate = date;
        $("#calendar").on("mousemove", forgetSlot);
    }
    
    function eventRenderCallback(event,element){
        
    	element.on("dblclick",function(event){
            //dblClickFunction(event.start) ;
           

         var quick_space = component.find('auraquickCMR'); 
         $A.util.removeClass(quick_space, "slds-hide");
         var showcmr = $A.get("e.c:HD_CMR_UpdateCMRID");
         showcmr.setParams({"changecmr":event.record}).fire();
            
        });   
    }

    function forgetSlot(){
        slotDate = null;
        $("#calendar").off("mousemove", forgetSlot);
    }
        
    function dblClickFunction(date){
             }
       
  
 

    $("#calendar").dblclick(function() {
        if(slotDate){
            //(slotDate.toISOString());
          
            
            var startdate = '';
            
          var sdate =  slotDate.toISOString();
            startdate = sdate
            if (sdate.split('T').length == 1){
                startdate += "T00:00:00";
            }
            startdate += "Z" ;

            var createRecordEvent = $A.get("e.force:createRecord");
            createRecordEvent.setParams({
           "entityApiName": "BMCServiceDesk__Change_Request__c",
          'defaultFieldValues': {
          'HD_Change_Status__c':'OPENED',   
          'BMCServiceDesk__Scheduled_Start_Date__c'	 : startdate ,
   },
    });
    createRecordEvent.fire();
            //do something with the date
        }
    });
       
       
     function addMonthstoDate(dt,monthnumber){
       var newDate = new Date(dt);
       newDate.setMonth( newDate.getUTCMonth() + monthnumber );

        var smonthDigit =  newDate.getUTCMonth() + 1;
        if (smonthDigit <= 9) {
            smonthDigit = '0' + smonthDigit;
        }
        
        var dayDigit = newDate.getDate();
        if(dayDigit <= 9){
          dayDigit = '0' + dayDigit;
        }
       
        
        return  newDate.getUTCFullYear() + "-" + smonthDigit + "-" + "01";
    }   

    function getNewCMRs(){
         var cev = component.getEvent('fetchEvent');
         cev.setParams({"eventtype": 'fetchEvent'}).fire();
       }   
       
     // $('.fc-day[data-date="2017-08-13"]').css("background-color", "#3C3C3D");
      function positionDataPicker(){

        component.set("v.showDate",true);
        var dateCmp = document.getElementById("dateId");
        var pos = $(".fc-today-button").position();
      
       dateCmp.style.position = "absolute";
       var posLeft = pos.left+20+$(".fc-today-button").outerWidth();

       
       var posTop = pos.top-20;
       dateCmp.style.left = posLeft+"px";
       dateCmp.style.top = posTop+"px";
        var dateComponent = component.find("dateId");
          if(component.get("v.showQuickView"))
          {
               $A.util.addClass(dateComponent, 'slds-hide');
          }
          else
          {
              $A.util.removeClass(dateComponent, 'slds-hide');
          }
          
       } 
       $('.fc-prev-button').click(function(){
           positionDataPicker();
           if(component.get("v.isListView") != true) {
               
            getNewCMRs();
           } 
           var vw = $('#calendar').fullCalendar('getView');
            if(vw.name == 'agendaDay' || vw.name == "agendaWeek")
            {
                backgroundForBlackout();
            }
        });
        
        $('.fc-next-button').click(function(){
            positionDataPicker();
            if(component.get("v.isListView") != true) {
                getNewCMRs();
            }
            var vw = $('#calendar').fullCalendar('getView');
            if(vw.name == 'agendaDay' || vw.name == "agendaWeek")
            {
                backgroundForBlackout();
            }
         }); 
       $('.fc-today-button').click(function(){
           positionDataPicker();
           if(component.get("v.isListView") != true) {
             getNewCMRs();
           }  
           backgroundForBlackout();
      
         }); 
       $('.fc-month-button').click(function(){
           positionDataPicker();
         }); 
       $('.fc-agendaWeek-button').click(function(){
           positionDataPicker();
           backgroundForBlackout();
           
         }); 
       $('.fc-agendaDay-button').click(function(){
           positionDataPicker();
           backgroundForBlackout();
         }); 
            
      
       function backgroundForBlackout(){
           var datenow = $('#calendar').fullCalendar('getDate').format();
           var today = new Date();
           var cmp_sdate = today;
           var cmp_edate = today;
          
          //alert("The current date of the calendar is " + datenow);
                var caldiv  = document.getElementById('calendar');
                var tds = caldiv.getElementsByTagName('td');
                var datetds = [];   
               for(var i = 0; i < tds.length; i++){
                   var ds = tds[i].dataset;
             
                   if( ds){
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
           var matchSO= [];
           var sdate;
           var edate;
           for(var i= 0; i < serviceoutages.length; i++ ){
                   var so = serviceoutages[i];
                   sdate = new Date(so.BMCServiceDesk__Start_Date__c);
                   edate = new Date(so.BMCServiceDesk__End_Date__c);
                   let cdate = new Date(datenow);
                 if(cmp_sdate <= edate && cmp_edate >= sdate){
                       
                       matchSO.push(so);
                   }
       }      
          
           
           if(matchSO.length > 0){
               for( var k = 0 ; k < datetds.length; k++ ){
                   
                   var el = datetds[k];
                   if(!el.dataset.date){
                       continue;
                   }
                   var dt = new Date(el.dataset.date);
                   for(var l=0 ; l < matchSO.length ; l++){
                       var so = matchSO[l];
                       sdate = new Date(so.BMCServiceDesk__Start_Date__c);
                       edate = new Date(so.BMCServiceDesk__End_Date__c);
                     
                        if(dt >= sdate && dt <= edate)
                         if(so.BMCServiceDesk__Blackout__c == true){
                                                    el.style.backgroundColor = "#524D4B";
                                                    
                                                    el.title = 'Blackout Priod :'+so.Name+ '  From '+sdate+ ' To '+edate;
  
                                                }
                                                else if(so.Service_Outage_Type__c != ''){
                                                   el.style.backgroundColor = "#D1F2EB";
                                                   el.title =  so.Service_Outage_Type__c+':'+so.Name + ' From '+sdate+ ' To '+edate;
                                                    
                                                }
                       }
                   }
               }//if matchSO
       }
       
  },
    

    tranformToFullCalendarFormat : function(cmp,events) {
        var eventArr = [];
        cmp.set("v.Changes",events);
        
        for(var i = 0;i < events.length;i++){
           var clr =  this.colorMap[events[i].BMCServiceDesk__Change_Category__c];
            eventArr.push({
                'id': events[i].Id,
                'start':moment(events[i].BMCServiceDesk__Scheduled_Start_Date__c).tz($A.get("$Locale.timezone")),
                'end':moment(events[i].BMCServiceDesk__Scheduled_End_Date__c).tz($A.get("$Locale.timezone")),
                'title':events[i].Change_Summary__c!=null ? events[i].Change_Summary__c.slice(0,20):'',
                'color': clr,
                'record':events[i],
                'timezoneParam':$A.get("$Locale.timezone")
            });
        }
        return eventArr;
    },
    
    
    fetchEvents : function(component,event,helper) {
        
       
        
        var action = component.get("c.getCalCMR"); 
        action.setStorable();
        var self = this;
        action.setParams({'sDate':component.get('v.startCalDate'), 'eDate': component.get('v.endCalDate')})
        action.setCallback(this, function(response) {
            var state = response.getState();
            var resp = response.getReturnValue();
            component.set("v.showSpinner",false);
            if(component.isValid() && state === "SUCCESS"){
                
                var categoriesColor = [];
                for(var changeCategory in resp.colorSettings)
                    {
                        var color = [];
                        this.colorMap[changeCategory] = resp.colorSettings[changeCategory];
                        color.push(changeCategory);
                        color.push('background:'+resp.colorSettings[changeCategory]+';');
                        categoriesColor.push(color);
                    }
                   component.set("v.serviceOutages", resp.serviceOutages);
                   var scolors = categoriesColor.slice(0,resp.changeCategoryRange);
                   component.set("v.categoriesColor",scolors);
               
                component.set("v.clistFilter",resp.changeRecords);
               /* var eventArr = self.tranformToFullCalendarFormat(component,resp.changeRecords,this.colorMap);

                
                if(component.get("v.isrerender") ==  false){
                    console.log(" IN Load");
                    component.set("v.isrerender", true);
                    self.loadDataToCalendar(component,eventArr,this);
                    
                
                }else{
                    
                    console.log(" IN render");
                    $('#calendar').fullCalendar('removeEvents');
                    $('#calendar').fullCalendar('addEventSource', eventArr);         
                    $('#calendar').fullCalendar('rerenderEvents' );
                } */
                
            }else if(state === "ERROR"){
                var errors = response.getError();
                HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message, false);
            }

            
        });
       
        $A.enqueueAction(action); 
        component.set("v.showSpinner",true);
    }, 
    
    
    
    getViewsRecords: function(cmp,event,helper,filterId){
        //var action = cmp.get("c.getViewRecords"); 
        var self = this;
        var list_views = [];
        var retc ;
        var opts = [];
        /*action.setParams({
            filterId : filterId}); */
        
           var action = cmp.get("c.getListViewRecords"); 
        //action.setParams({'calDate':cmp.get('v.calDate')}) ; 
        action.setParams({
            filterId : filterId});
        action.setCallback(this, function(response) {
         
			cmp.set("v.showSpinner",false);            
            var state = response.getState();
            var resp = response.getReturnValue();
            if(cmp.isValid() && state === "SUCCESS"){
                cmp.set("v.clistFilter",resp);
            }else if(state === "ERROR"){
                
                var errors = response.getError();
                console.log(errors);
                HD_Error_Logger.createLogger(cmp, event, helper, errors[0].message, errors[0].message, false);
            }

 
        });

        if( filterId != null && filterId.trim() != ''){
            $A.enqueueAction(action); 
            cmp.set("v.showSpinner",true);
        }
            
       
         

    },
    
    inverseViewIcon: function(comp,id){
        
        var lst_icon = document.getElementById('lst-icon');
        var lst_icon_inverse = document.getElementById('lst-icon-inverse');
        var cal_icon = document.getElementById('cal-icon');
        var cal_icon_inverse = document.getElementById('cal-icon-inverse');
        if(id == 'list'){
            
            lst_icon.style.display = "none";
            lst_icon_inverse.style.display = "";
            cal_icon.style.display = '';
            cal_icon_inverse.style.display = "none";
        }else{
            lst_icon.style.display = '';
            lst_icon_inverse.style.display = "none";
            cal_icon.style.display = "none";
            cal_icon_inverse.style.display = '';
            
        }
        
    },
    
    navigateToDateHelper: function(cmp,evt,helper){
        
        var date = $.fullCalendar.moment(evt.getSource().get("v.value"));
        
        
        $('#calendar').fullCalendar( 'gotoDate', date );
        helper.compareDateRange(cmp,evt,helper);
        
        
    },
    
    
    addNumofMonths: function(dt,number){
        var newDate = new Date(dt);
       newDate.setUTCMonth( newDate.getUTCMonth() + number );

        var smonthDigit =  newDate.getUTCMonth() + 1;
        if (smonthDigit <= 9) {
            smonthDigit = '0' + smonthDigit;
        }
        
        var dayDigit = newDate.getDate();
        if(dayDigit <= 9){
          dayDigit = '0' + dayDigit;
        }
       
        
        return  newDate.getUTCFullYear() + "-" + smonthDigit + "-" + "01";
    },
    
    
    compareDateRange: function(component,evt,helper){
       var clDate =  component.get('v.calDate')
        var moment = $('#calendar').fullCalendar('getDate');
        var thisDate = new Date(moment);
        
        var dtstr =  helper.addNumofMonths(thisDate,0)
        component.set('v.calDate', dtstr);  
        
        if(component.get("v.calDate") >= component.get("v.endCalDate") || component.get("v.calDate") <= component.get("v.startCalDate")){
               var nwenddate = helper.addNumofMonths(component.get("v.calDate"), 3);
               var nwstartdate = helper.addNumofMonths(component.get("v.calDate"), -3);
                 component.set("v.endCalDate", nwenddate);
                 component.set("v.startCalDate", nwstartdate);
                 helper.fetchEvents(component);
            }
         
    },
    
    setDates: function(cmp,event){
       var today = new Date();
        var dt = new Date();
        var stDate = new Date();
        var endDate = new Date();
        
        stDate.setUTCMonth( dt.getUTCMonth() - 3 );
        endDate.setUTCMonth( dt.getUTCMonth() + 3 );
       
        var smonthDigit =  stDate.getUTCMonth() + 1;
        if (smonthDigit <= 9) {
            smonthDigit = '0' + smonthDigit;
        }
        
        var emonthDigit =  endDate.getUTCMonth() + 1;
        if (emonthDigit <= 9) {
            emonthDigit = '0' + emonthDigit;
        }

        cmp.set('v.startCalDate', stDate.getUTCFullYear () + "-" + smonthDigit + "-" + "01");
        cmp.set('v.endCalDate',   endDate.getUTCFullYear () + "-" + emonthDigit + "-" + "01");
    },
    
    filter: function(component,resp){
        
          var eventArr = this.tranformToFullCalendarFormat(component,resp);//this.tranformToFullCalendarFormat(component,resp.changeRecords,this.colorMap);

                
                if(component.get("v.isrerender") ==  false){
                    component.set("v.isrerender", true);
                    this.loadDataToCalendar(component,eventArr,this,component.get("v.serviceOutages"));
                    
                
                }else{
                    
                    $('#calendar').fullCalendar('removeEvents');
                    $('#calendar').fullCalendar('addEventSource', eventArr);         
                    $('#calendar').fullCalendar('rerenderEvents' );
                } 
        
        
    },
    
    setUserType: function(component,event,helper){
        var action = component.get("c.getUserType"); 
        action.setCallback(this, function(response) {
            var state = response.getState();
            var resp = response.getReturnValue();
            if(component.isValid() && state === "SUCCESS"){
                if(resp != null && resp != ''){
                    if( resp.includes('CAB')){
                        component.set("v.isCABManager",true);
                    }
                }
            }else if(state === "ERROR"){
                var errors = response.getError();
                HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message, false);
            }

        }); 
        $A.enqueueAction(action);                    
    }, 
    
    getListViewOptions: function(component){
        var action = component.get("c.getAllListViews");
        action.setCallback(this,function(response){
           var resp = response.getReturnValue();
           var state = response.getState();
            var optionValues=[];
            if( state === "SUCCESS"){
            //{'label': 'New', 'value': 'new'},
                resp.forEach((list)=>{
                    var temp = {};
                    temp.label = list.Name;
                    temp.value = list.Id;
                    optionValues.push(temp);
                  })
                component.set("v.listViewOptions",optionValues);
            }else if(state === "ERROR"){
                var errors = response.getError();
                HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message, false);
             }
        });
        $A.enqueueAction(action);       
    }
    
    
})