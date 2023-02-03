({createGraph : function(cmp, temp) {
        debugger;
    try{
        var dataMap = {"chartLabels": Object.keys(temp),
                       "chartData": Object.values(temp)
                       };
        
      //  var el = cmp.find('barChart').getElement();
      //  var ctx = el.getContext('2d');
         var el = cmp.find('barChart').getElement();
       	var ctx = el.getContext('2d');
    
   
            
      //  var ctx = component.find("linechart").getElement()
        
         new Chart(ctx, {
            type: 'bar',
            data: {
                labels: dataMap.chartLabels,
                datasets: [
                    {
                        label: "Impacted Accounts count",
                      
                        borderColor:'Blue',
                        //backgroundColor : ["#3e95cd", "#8e5ea2","#3cba9f","#e8c3b9"],
                        backgroundColor: "rgba(255,153,0,0.4)",
                        hoverBackgroundColor: "rgba(255,170,30,0.6)",
                        data: dataMap.chartData
                     
                           
                    }
                ]
            },
             options: {
                        title: {
                            display: true,
                            text: 'Associated Accounts by Customer Tier'
                        },
                 		scales: {
                                    yAxes: [{
                                      scaleLabel: {
                                        display: true,
                                        labelString: 'Associated Accounts'
                                      }
                                    }],
                            		xAxes: [{
                                      scaleLabel: {
                                        display: true,
                                        labelString: 'Customer Tier'
                                      }
                                    }]
                                 }   
                    } 
             
         });
    	
    }
    catch(err){
        debugger;
        console.log('eee**'+err.message);
    }
            
           /* new Chart(el,{
                    type: 'bubble',
                    data: dataChart,
                    options: optionsChart
                });*/
	},
    createLineGraph : function(cmp, temp) {
        
        var label = [];
        var firstValue = [];
        var secondValue = [];
        
        for(var a=0; a< temp.length; a++){
            console.debug(temp[a]["label"]);
            label.push(temp[a]["label"]);
            firstValue.push(temp[a]["firstValue"]);
            secondValue.push(temp[a]["secondValue"]);                     
        }    
        var el = cmp.find('lineChart').getElement();
        var ctx = el.getContext('2d');
        
        new Chart(ctx, {
            type: 'line',
            data: {
                    labels: label,
                    datasets: [{
                      label: 'First Values',
                      data: firstValue,
                      backgroundColor: "rgba(153,255,51,0.4)"
                    }, {
                      label: 'Second Values',
                      data: secondValue,
                      backgroundColor: "rgba(255,153,0,0.4)"
                    }]
                  }
        });
        
	}
    
})