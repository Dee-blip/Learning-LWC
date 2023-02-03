({
	doInit : function(component, event, helper)
    {
        //This is the afterScriptsLoaded helper
        //var spinner = component.find("mySpinner");
        //$A.util.removeClass(spinner, "slds-hide");
        
        var v = component.get("v.nomonths");
        
        var action = component.get("c.getUsageJSON");
        action.setParams({ "months" : v });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                
                //var spinner = component.find("mySpinner");
        		//$A.util.addClass(spinner, "slds-hide");
                
                var dataObj= response.getReturnValue();
                console.log('===='+dataObj);
                component.set("v.data",dataObj);
                helper.barchart(component,event,helper);
            }
        });
        $A.enqueueAction(action);
    },
    
    barchart : function(component, event, helper)
    {
        var v = component.get("v.nomonths");
        
        var jsonData = component.get("v.data");
        var dataObj = JSON.parse(jsonData);
        console.log(dataObj);
        new Highcharts.Chart({
            chart: {
                plotBackgroundColor: null,
                plotBorderWidth: null,
                plotShadow: false,
                renderTo: component.find("chart").getElement(),
                type: 'bar',
            },
            title: {
                text: component.get("v.chartTitle")+' (Bar Chart)'
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
                pointFormat: '{series.name}: <b>{point.y}</b> ',  
                 
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
                    point: {
                        events: {
                            click: function (event) {
                                component.set("v.Spinner", true);
                                //var spinner = component.find("mySpinner");
        						//$A.util.removeClass(spinner, "slds-hide");
                                //$A.util.addClass(spinner, "slds-show");
                                console.log("inClick");
                                var n = this.name;
                                console.log(n);
                                if(n == 'true' || n == 'false')
                                {
                                    component.set("v.parentAttribute1", n);
                                    var attribute1 = component.get('v.parentAttribute1');
                                    var childComponent = component.find('child');
                                    childComponent.myMethod(attribute1);   
                                }
                                else if(n == 'No Login')
                                {
                                    var childComponent = component.find('child');
                                    childComponent.sixmonths(v);   
                                }
                                else
                                {
                                    var childComponent = component.find('child');
                                    childComponent.usernotowner(v);
                                }
                                component.set("v.Spinner", false);
                                //$A.util.addClass(spinner, "slds-hide");
                                //$A.util.removeClass(spinner, "slds-show");
                            }
                        }
                    }
                }
                }
            ,
            series: [{
                name:'Usage',
                data:dataObj
            }]
        }); 
    }
})