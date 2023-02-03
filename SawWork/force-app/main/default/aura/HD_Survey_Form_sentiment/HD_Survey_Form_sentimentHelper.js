({
    faceSetHelper : function(cmp,event) {
        var sentiments = ['unhappy','neutral','happy'];
        var sentiment = event.getSource().get('v.value')||cmp.get('v.value');
        var sentiment_selected_Class = event.getSource().get('v.iconClass');
        console.log(sentiment,sentiment_selected_Class );
        if(!sentiment_selected_Class)
        {   if(sentiment)
        {
            cmp.find(sentiment).set('v.iconClass','glow');
        }
            
        }
        
        sentiments.forEach(function(senti){
            //console.log('--> ',senti); 
            if(senti === sentiment) {
                //setting the values
                cmp.set('v.value',sentiment);
                event.getSource().set('v.iconClass','glow');
            }
            else
            {
                var other_sentiment = cmp.find(senti);
                other_sentiment.set('v.iconClass','')
                //console.log(other_sentiment);
            }
            
        });
    }
})