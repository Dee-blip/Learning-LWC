({
    doInit : function(component, event, helper)
    {
        
        var currentdate = new Date(); 
        var datetime = currentdate.getFullYear() + "-" + (currentdate.getMonth()+1) + "-" + currentdate.getDate() + "T" 
        + currentdate.getHours() + ":"  
        + currentdate.getMinutes() + ":" 
        + currentdate.getSeconds() + ".000Z" ;
        console.log(datetime);
        
        var v = component.get("v.nomonths");
        console.log(v)
        
        var wholeObj = new Set();
        var nidpidSet = new Set();
        var count=1,max_count = v/15,rem0=0,rem1=0,rem2=0;    
        
        //console.log(max_count);
        
            var action1 = component.get("c.getTicketsJSON");
        action1.setParams({ "months" : count , "now" : datetime});
            action1.setCallback(this, function(response) {
               
                if(count > max_count){
                    console.log(nidpidSet)
                    console.log(wholeObj)
                    
                    //console.log("0"+wholeObj.size)
                    
                    var mapSource = new Map();
                    var idSet = new Set();
                    var bluemoonid = [];
                    var rareid = [];
                    var oftenid = [];
                    var regularid = [];
                    var nerdyid = [];
                    nidpidSet.forEach(function(ids){
                    	var cpid = ids.split("#")
                        if(idSet.has(cpid[0]))	
                        {    
                            mapSource.set(cpid[0],(mapSource.get(cpid[0]))+1);
                        }
                        else
                        {    
                            mapSource.set(cpid[0],1);
                        	idSet.add(cpid[0]);    
                        }
                    });
                    
                    //console.log("00"+idSet.size)
                    //console.log("000"+mapSource.size)
                    
                    console.log(mapSource);
                    var c1=0,c10=0,c100=0,c500=0,c1k=0;
                    var mapLeadSource = new Map();
                    mapSource.forEach(function(value,key){
                        if(value<10)
                        {    
                            c1++;
                            bluemoonid.push(key); 
                        }
                        else if(value>=10 && value<100)
                        {    
                            c10++;
                            rareid.push(key); 
                        }
                        else if(value>=100 && value<500)
                        {    
                            c100++;
                            oftenid.push(key); 
                        }
                        else if(value>=500 && value<1000)
                        {    
                            c500++;
                            regularid.push(key); 
                        }
                        else
                        {    
                            c1k++;
                            nerdyid.push(key); 
                        }
                    });
                    //console.log(bluemoonid);
                    mapLeadSource.set("Blue Moon Users(0-10)", c1);
                    mapLeadSource.set("Rare Users(10-100)", c10);
                    mapLeadSource.set("Often Users(100-500)", c100);
                    mapLeadSource.set("Regular Users(500-1000)", c500);
                    mapLeadSource.set("Nerdy Users(Above 1000)", c1k);
                    console.log(mapLeadSource);
                    
                    var str = '['
                    var c = 0;
                    mapLeadSource.forEach(function(key,value,map){
                        str = str.concat('{"y":')
                        str = str.concat(key)
                        str = str.concat(',"name":"')
                        str = str.concat(value)
                        if(c != 4)
                        	str = str.concat('"},')
                        else
                            str = str.concat('"}')
                        c++;
                    });
                    str = str.concat(']')
                    console.log(str)
                    component.set("v.data1",str);
                    //component.set("v.userids",userid);
                    component.set("v.bluemoonids",bluemoonid);
                    component.set("v.rareids",rareid);
                    component.set("v.oftenids",oftenid);
                    component.set("v.regularids",regularid);
                    component.set("v.nerdyids",nerdyid);
                    //helper.Donutchart(component,event,helper);
                    
                    
                    
                    
                    var mapSource1 = new Map();
                    var idSet1 = new Set();
                    var bluemoonid1 = [];
                    var rareid1 = [];
                    var oftenid1 = [];
                    var regularid1 = [];
                    var nerdyid1 = [];
                    wholeObj.forEach(function(ids){
                    	var cpid = ids.split("*")
                        if(idSet1.has(cpid[1]))	
                        {    
                            mapSource1.set(cpid[1],(mapSource1.get(cpid[1]))+1);
                        }
                        else
                        {    
                            mapSource1.set(cpid[1],1);
                        	idSet1.add(cpid[1]);    
                        }
                    });
                    
                    //console.log("00"+idSet.size)
                    //console.log("000"+mapSource.size)
                    
                    console.log(mapSource1);
                    var c11=0,c101=0,c1001=0,c5001=0,c1k1=0;
                    var mapLeadSource1 = new Map();
                    mapSource1.forEach(function(value,key){
                        if(value<50)
                        {    
                            c11++;
                            bluemoonid1.push(key); 
                        }
                        else if(value>=50 && value<100)
                        {    
                            c101++;
                            rareid1.push(key); 
                        }
                        else if(value>=100 && value<1000)
                        {    
                            c1001++;
                            oftenid1.push(key); 
                        }
                        else if(value>=1000 && value<2000)
                        {    
                            c5001++;
                            regularid1.push(key); 
                        }
                        else
                        {    
                            c1k1++;
                            nerdyid1.push(key); 
                        }
                    });
                    //console.log(bluemoonid);
                    mapLeadSource1.set("Blue Moon Users(0-50)", c11);
                    mapLeadSource1.set("Rare Users(50-100)", c101);
                    mapLeadSource1.set("Often Users(100-1000)", c1001);
                    mapLeadSource1.set("Regular Users(1000-2000)", c5001);
                    mapLeadSource1.set("Nerdy Users(Above 2000)", c1k1);
                    console.log(mapLeadSource1);
                    
                    var str1 = '['
                    var c1 = 0;
                    mapLeadSource1.forEach(function(key,value,map){
                        str1 = str1.concat('{"y":')
                        str1 = str1.concat(key)
                        str1 = str1.concat(',"name":"')
                        str1 = str1.concat(value)
                        if(c1 != 4)
                        	str1 = str1.concat('"},')
                        else
                            str1 = str1.concat('"}')
                        c1++;
                    });
                    str1 = str1.concat(']')
                    console.log(str1)
                    component.set("v.data",str1);
                    //component.set("v.userids",userid);
                    component.set("v.bluemoonids1",bluemoonid1);
                    component.set("v.rareids1",rareid1);
                    component.set("v.oftenids1",oftenid1);
                    component.set("v.regularids1",regularid1);
                    component.set("v.nerdyids1",nerdyid1);
                    
                    helper.Linechart(component,event,helper);
                    
                    helper.Donutchart(component,event,helper);
                    return
                }
                    
                var state = response.getState();
                console.log(state);
                if (state === "SUCCESS") {
                    var dataObj = response.getReturnValue();
                    //console.log("="+dataObj)
 
                    dataObj = JSON.parse(dataObj);
                    //console.log(dataObj)
					
                    //console.log('value');
                    dataObj.forEach(function(value){
                        //console.log(value.Ids);
                        var ids = value.Ids.split("*")
                        //console.log(ids[1])
                        nidpidSet.add(ids[1])
                        
                        var ids1 = value.Ids.split("#")
                        //console.log(ids1[0])
                        wholeObj.add(ids1[0])
                        
                        //wholeObj.add(value.Ids)
                    });
                } 
                
                count = count+1;
                action1.setParams({ "months" : count , "now" : datetime});
                $A.enqueueAction(action1);
            });
        	$A.enqueueAction(action1);
        
        //This is the afterScriptsLoaded helper
        //component.set("v.Spinner", true);
        /*var v = component.get("v.nomonths");
        console.log(v);
        
        var action = component.get("c.getFrequencyJSON");
        
        action.setParams({ "noofmonths" : v });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var dataObj = response.getReturnValue();
                console.log('===='+dataObj);
                component.set("v.data",dataObj);
                helper.Linechart(component,event,helper);
                //helper.Donutchart(component,event,helper);
                
                //component.set("v.Spinner", true);
				
                console.log('fis')
                dataObj = JSON.parse(dataObj);
                console.log(dataObj)
                var myJSON = JSON.stringify(dataObj);
                console.log(myJSON)
                console.log(dataObj[0]["y"]);
                console.log('fis')
            } 
        });
        $A.enqueueAction(action);
        //component.set("v.Spinner", false);
    },
    
    doInitAgain : function(component, event, helper)
    {        
        var currentdate = new Date(); 
        var datetime = currentdate.getFullYear() + "-" + (currentdate.getMonth()+1) + "-" + currentdate.getDate() + "T" 
        + currentdate.getHours() + ":"  
        + currentdate.getMinutes() + ":" 
        + currentdate.getSeconds() + ".000Z" ;
        console.log(datetime);
        
        //component.set("v.Spinner", true);
        var v = component.get("v.nomonths");
        
        var wholeObj = new Set();
        var count=1,max_count = v/3,rem0=0,rem1=0,rem2=0;    
        
        console.log(max_count);
        
            var action1 = component.get("c.getTicketsJSON");
        action1.setParams({ "months" : count , "now" : datetime});
            action1.setCallback(this, function(response) {
               
                if(count > max_count){
                    console.log(wholeObj)
                    
                    console.log("0"+wholeObj.size)
                    
                    var mapSource = new Map();
                    var idSet = new Set();
                    var bluemoonid = [];
                    var rareid = [];
                    var oftenid = [];
                    var regularid = [];
                    var nerdyid = [];
                    wholeObj.forEach(function(ids){
                    	var cpid = ids.split("#")
                        if(idSet.has(cpid[0]))	
                        {    
                            mapSource.set(cpid[0],(mapSource.get(cpid[0]))+1);
                        }
                        else
                        {    
                            mapSource.set(cpid[0],1);
                        	idSet.add(cpid[0]);    
                        }
                    });
                    
                    console.log("00"+idSet.size)
                    console.log("000"+mapSource.size)
                    
                    console.log(mapSource);
                    var c1=0,c10=0,c100=0,c500=0,c1k=0;
                    var mapLeadSource = new Map();
                    mapSource.forEach(function(value,key){
                        if(value<10)
                        {    
                            c1++;
                            bluemoonid.push(key); 
                        }
                        else if(value>=10 && value<100)
                        {    
                            c10++;
                            rareid.push(key); 
                        }
                        else if(value>=100 && value<500)
                        {    
                            c100++;
                            oftenid.push(key); 
                        }
                        else if(value>=500 && value<1000)
                        {    
                            c500++;
                            regularid.push(key); 
                        }
                        else
                        {    
                            c1k++;
                            nerdyid.push(key); 
                        }
                    });
                    console.log(bluemoonid);
                    mapLeadSource.set("Blue Moon Users(0-10)", c1);
                    mapLeadSource.set("Rare Users(10-100)", c10);
                    mapLeadSource.set("Often Users(100-500)", c100);
                    mapLeadSource.set("Regular Users(500-1000)", c500);
                    mapLeadSource.set("Nerdy Users(Above 1000)", c1k);
                    console.log(mapLeadSource);
                    
                    var str = '['
                    var c = 0;
                    mapLeadSource.forEach(function(key,value,map){
                        str = str.concat('{"y":')
                        str = str.concat(key)
                        str = str.concat(',"name":"')
                        str = str.concat(value)
                        if(c != 4)
                        	str = str.concat('"},')
                        else
                            str = str.concat('"}')
                        c++;
                    });
                    var str = str.concat(']')
                    console.log(str)
                    component.set("v.data1",str);
                    //component.set("v.userids",userid);
                    component.set("v.bluemoonids",bluemoonid);
                    component.set("v.rareids",rareid);
                    component.set("v.oftenids",oftenid);
                    component.set("v.regularids",regularid);
                    component.set("v.nerdyids",nerdyid);
                    helper.Donutchart(component,event,helper);
                    return
                }
                    
                var state = response.getState();
                console.log(state);
                if (state === "SUCCESS") {
                    var dataObj = response.getReturnValue();
                    //console.log("="+dataObj)
 
                    dataObj = JSON.parse(dataObj);
                    //console.log(dataObj)
					
                    //console.log('value');
                    dataObj.forEach(function(value){
                        //console.log(value.Ids);
                        wholeObj.add(value.Ids)
                    });
                } 
                
                count = count+1;
                action1.setParams({ "months" : count , "now" : datetime});
                $A.enqueueAction(action1);
            });
        	$A.enqueueAction(action1);*/
	},
    
    Linechart : function(component,event,helper) {
        
        //var v = component.get("v.nomonths");
        var bluemoonIds = component.get("v.bluemoonids1");
        var rareIds = component.get("v.rareids1");
        var oftenIds = component.get("v.oftenids1");
        var regularIds = component.get("v.regularids1");
        var nerdyIds = component.get("v.nerdyids1");
        
        var jsonData = component.get("v.data");
        var dataObj = JSON.parse(jsonData);
        console.log(dataObj);
        var str = new Array();
        var i,n;
        
        for(i=0;i<dataObj.length;i++)
        {
            str.push(dataObj[i].name);
        }
        component.set("v.xAxisCategories",str);
        new Highcharts.Chart({
            chart: {
                plotBackgroundColor: null,
                plotBorderWidth: null,
                plotShadow: false,
                renderTo: component.find("chart").getElement(),
                type: 'line'
            },
            title: {
                text: 'No.of Modifications vs No.of Users'   //component.get("v.chartTitle")+' (Line Chart)'
            },
            subtitle: {
                text: component.get("v.chartSubTitle")
            },
            xAxis: {
                categories: component.get("v.xAxisCategories"),
                crosshair: true
            },
            yAxis: {
                min: 0,
                title:
                {
                    text: component.get("v.yAxisParameter")
                }
            },
            tooltip: {
                pointFormat: '{series.name}: <b>{point.y}</b>',
                
            },
            plotOptions: {
                line: {
                    dataLabels: {
                        
                        enabled: true
                    },
                    enableMouseTracking: true
                },
                series: {
                    cursor: 'pointer',  
                    point:{
                        events: {
                            click: function (event) {
                                component.set("v.Spinner", true);
                                console.log("inClick");
                                var n = this.name;
                                console.log(n);
                                if(n == 'Blue Moon Users(0-50)')
                                {
                                    var childComponent = component.find('child');
                                    //childComponent.modifications(0,50,v);   
                                    childComponent.bluemoont(bluemoonIds);   
                                }
                                else if(n == 'Rare Users(50-100)')
                                {
                                    var childComponent = component.find('child');
                                    //childComponent.modifications(50,100,v);  
                                    childComponent.bluemoont(rareIds); 
                                }
                                else if(n == 'Often Users(100-1000)')
                                {
                                    var childComponent = component.find('child');
                                    //childComponent.modifications(100,500,v);   
                                    childComponent.bluemoont(oftenIds);
                                }
                                else if(n == 'Regular Users(1000-2000)')
                                {
                                    //console.log("in helper");
                                    var childComponent = component.find('child');
                                    //childComponent.modifications(1000,5000,v);  
                                    childComponent.bluemoont(regularIds);
                                }
                                else
                                {
                                    var childComponent = component.find('child');
                                    //childComponent.modifications(5000,1000000,v);
                                    childComponent.bluemoont(nerdyIds);
                                }
                                component.set("v.Spinner", false);
                            }
                            
                        }
                    }
                }
            },
            series: [{
                name:'No.of Users',
                data:dataObj
                
            }]
            
        });
        
    },
    
    Donutchart : function(component,event,helper) {
        //component.set("v.Spinner", true);
        var jsonData = component.get("v.data1");
        var bluemoonIds = component.get("v.bluemoonids");
        var rareIds = component.get("v.rareids");
        var oftenIds = component.get("v.oftenids");
        var regularIds = component.get("v.regularids");
        var nerdyIds = component.get("v.nerdyids");
        var dataObj = JSON.parse(jsonData);
 		console.log(dataObj);
        console.log(bluemoonIds);
        //console.log(userIds);
        new Highcharts.Chart({
            chart: {
                renderTo: component.find("donutchart").getElement(),
                type: 'pie',
                options3d: {
                    enabled: true,
                    alpha: 45
                }
            },
            title: {
                text: 'No.of Tickets vs No.of Users'  //component.get("v.chartTitle")+' (Donut Chart)'
            },
            subtitle: {
                text: component.get("v.chartSubTitle")
            },
            tooltip: {
                pointFormat: '{series.name}: <b>{point.y}</b>'   //<b>{point.percentage:.1f}%</b>'
            },
            plotOptions: {
                pie: {
                    innerSize: 100,
                    depth: 45
                },
                
                series: {
                    cursor: 'pointer',  
                    point:{
                        events: {
                            click: function (event) {
                                component.set("v.Spinner", true);
                                console.log("inClick");
                                var n = this.name;
                                console.log(n);
                                if(n == 'Blue Moon Users(0-10)')
                                {
                                    var childComponent = component.find('child');
                                    childComponent.bluemoont(bluemoonIds);   
                                }
                                else if(n == 'Rare Users(10-100)')
                                {
                                    var childComponent = component.find('child');
                                    //childComponent.raret(rareIds);   
                                    childComponent.bluemoont(rareIds); 
                                }
                                else if(n == 'Often Users(100-500)')
                                {
                                    var childComponent = component.find('child');
                                    //childComponent.oftent(oftenIds);   
                                    childComponent.bluemoont(oftenIds); 
                                }
                                else if(n == 'Regular Users(500-1000)')
                                {
                                    var childComponent = component.find('child');
                                    //childComponent.regulart(regularIds);   
                                    childComponent.bluemoont(regularIds); 
                                }
                                else
                                {
                                    var childComponent = component.find('child');
                                    //childComponent.nerdyt(nerdyIds);
                                    childComponent.bluemoont(nerdyIds); 
                                }
                                component.set("v.Spinner", false);
                            }
                            
                        }
                    }
                }
                
            },
            series: [{
                type: 'pie',
                name:'No.of Users',
                data:dataObj
            }]
 
        });
 		//component.set("v.Spinner", false);
    }
})