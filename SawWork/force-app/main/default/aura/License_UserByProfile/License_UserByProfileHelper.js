({
    doInit : function(component, event, helper)
    {
        //This part is the initAction method
        
        //This is the afterScriptsLoaded helper
        var action = component.get("c.getUsersJSON");
        action.setCallback(this, function(response) {
            var state = response.getState();
            //alert(state);
            
            if (state === "SUCCESS") {
                var dataObj= response.getReturnValue();
                //jsonData = dataObj;
                console.log('===='+dataObj);
                component.set("v.data",dataObj);
                helper.piechart(component,event,helper);
                //helper.Linechart(component,event,helper);
                //helper.donutchart(component,event,helper);
            }
        });
        $A.enqueueAction(action);
    },
    piechart : function(component,event,helper) {
        var jsonData = component.get("v.data");
        var dataObj = JSON.parse(jsonData);
        console.log(dataObj);
        new Highcharts.Chart({
            chart: {
                plotBackgroundColor: null,
                plotBorderWidth: null,
                plotShadow: false,
                renderTo: component.find("chart").getElement(),
                type: 'pie'
            },
            title: {
                text: component.get("v.chartTitle")+' (Pie Chart)'
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
                formatter: function (e) {
                    return this.point.name;
                }
            },
            plotOptions: {
                pie: {
                    allowPointSelect: true,
                    cursor: 'pointer',
                    dataLabels: {
                        formatter: function (e) {
                            return this.point.name;
                        },
                        enabled: true,
                        format: '<b>{point.name}</b>: {point.y} ',
                        style: {
                            color: (Highcharts.theme && Highcharts.theme.contrastTextColor) || 'black'
                        },
                        formatter: function() {
                            return this.percentage.toFixed(2) + '%';
                        }
                    },
                    
                    showInLegend: true
                },
                series: {
                    cursor: 'pointer',
                    point: {
                        events: {
                            click: function (event) {
                                component.set("v.Spinner", true);
                                console.log("inClick");
                                var n = this.name;
                                
                               // helper.getUsers(component,event,helper,n);
                                
                                /*var evt = $A.get("e.c:License_ChartToTable");
                            evt.setParams({ "ProfileName": "fgyg"});
                            evt.fire();
                            console.log("inClick1");
                            var prof = "55" ;*/
                            //alert(n);
                            var listUsers1 = component.get("c.listUsers1");
                            listUsers1.setParams({"profileName":n});
                            listUsers1.setCallback(this,function(resp){
                                var state = resp.getState();
                                if(state == "SUCCESS")
                                { 
                                    var response = resp.getReturnValue();
                                    console.log(response);   
                                    component.set("{!v.userlist}", response);
 
                                }
                                else if(state == "RUNNING")
                                {
                                    
                                }
                                    else if(state == "ERROR")
                                    {
                                        var error = resp.getError();
                                        if(error)
                                        {
                                            console.log(error);
                                        }
                                    }
                            });
                            $A.enqueueAction(listUsers1);    
                            component.set("v.Spinner", false);
                            //location.reload();
                        }
                    }
                    }    
                }
            },
            
             legend: {
                    enabled: true,
                    layout: 'vertical',
                    align: 'right',
                    width: 200,
                    //horizontalAlign: 'bottom',
                    verticalAlign: 'bottom',
                    x: -100,
                    y: 0,
                    useHTML: true,
                    labelFormatter: function() {
                        return '<div style="text-align: left; width:400px;float:left;">' + this.name + '</div><div style="width:40px; float:left;text-align:right;">' + this.y + ' Users</div>';
                    }
                },
            
            series: [{
                name:'Profile',
                data:dataObj
            }],

            exporting: {
                enabled : true,
                sourceWidth: 1200,
                sourceHeight: 800,
                buttons: {
                    contextButton: {
                        menuItems: [ 'downloadJPEG', 'downloadPNG', 'downloadPDF', 'downloadSVG']
                    }
                },
                chartOptions: {
                    legend: {
                        enabled: false
                    }
                }
            }
            
        });
        
    },
    
  /*  getUsers : function(component, event, helper,n)
    {
        alert(n);
        var listUsers1 = component.get("c.listUsers1");
        listUsers1.setParams({"profileName":n});
        listUsers1.setCallback(this,function(resp){
            var state = resp.getState();
            if(state == "SUCCESS")
            {
                var response = resp.getReturnValue();
                console.log(response);   
                component.set("{!v.userlist}", response);
            }
            else if(state == "RUNNING")
            {
                
            }
                else if(state == "ERROR")
                {
                    var error = resp.getError();
                    if(error)
                    {
                        console.log(error);
                    }
                }
        });
        $A.enqueueAction(listUsers1);
        //location.reload();
    }*/
})