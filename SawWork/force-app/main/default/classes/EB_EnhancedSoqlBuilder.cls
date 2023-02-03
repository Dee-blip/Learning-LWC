/*
Author : Sharath K
Description : This is an extension of the SoqlBuilder class. With this class ,we can search by Account fields that are Numeric in nature
*/

public class EB_EnhancedSoqlBuilder extends EB_SoqlBuilder
{
    public List<String> dataTypes = new List<String>();
    String fieldList;
    
    //constructor
    public EB_EnhancedSoqlBuilder()
    {
        strWhereClause = '';
        strSQL = '';
        tableName = '';
    }
     
     public void setFields(String fields){
     fieldList=fields;
     }

     public override String buildSelectClause(){
     if(fieldList!=null){
         strSelectSOQL = ' Select ' + fieldList + ' FROM ' + tableName + ' where ';
         }
      else
          strSelectSOQL = ' Select Id ' + ' FROM ' + tableName + ' where ';
     return strSelectSOQL; 
     }
    //clears all the lists    
    public override void clearSearchCriteria()    
    {
        try
        {        
            searchFields.clear();        
            searchOperators.clear();        
            searchValues.clear();       
            logicalOperators.clear();
            dataTypes.clear();  
        } 
        catch(Exception e)
        {
            System.debug(e.getMessage());
        } 
    }
    
    public void addSearchCriteria(String searchField, String searchOperator, String searchValue, String logicalOperator, String dataType)    
    { 
        try
        {       
            searchFields.add(searchField);        
            searchOperators.add(searchOperator);        
            searchValues.add(searchValue);          
            logicalOperators.add(logicalOperator);
            dataTypes.add(dataType); 
        }
        catch(Exception e)
        {
            System.debug(e.getMessage());
        }   
    }
    
    public override void removeSearchCriteria(String searchField, String searchOperator, String searchValue)
    {        
        Integer i;  
        try
        {      
            for (i = 0; i < searchFields.size(); i++)
            {            
                if ((searchFields.get(i) == searchField) && (searchOperators.get(i) == searchOperator) && (searchValues.get(i) == searchValue))
                {                
                    searchFields.remove(i);                
                    searchOperators.remove(i);                
                    searchvalues.remove(i);                
                    logicalOperators.remove(i); 
                    dataTypes.remove(i);           
                }        
            } 
        }
        catch(Exception e)
        {
            System.debug(e.getMessage());
        }   
    }
    
    
    public override String buildWhereClause()
    {        
        Integer i = 0;     
          
        String tempstrSubSQL1;
        String tempstrSubSQL2;    
        String intRetVal = '0';
        
        try
        {
            if ((searchFields.size() == searchOperators.size()) && (searchOperators.size() == searchValues.size()))
            {
                Integer flag = 0;

                while (i<searchFields.size())
                {
                    if (searchOperators.get(i) == '%')
                    {
                         strTemp = '%' + searchValues.get(i) + '%';
                         if(flag ==0){
                            if(dataTypes.get(i)=='String')
                                strSubSQL = searchFields.get(i) + ' LIKE '+ '\'' + '%' + searchValues.get(i)+'%' + '\'';
                            else
                                strSubSQL = searchFields.get(i) + ' LIKE '+  '%' + searchValues.get(i)+'%' ;
                            }
                         else{
                            if(dataTypes.get(i)=='String')
                                strSubSQL = strSubSQL + searchFields.get(i) + ' LIKE '+ '\'' + '%' + searchValues.get(i)+'%'+ '\'';
                            else
                                strSubSQL = strSubSQL + searchFields.get(i) + ' LIKE '+ '%' + searchValues.get(i)+'%';
                            }
                         if(i<(logicalOperators.size())-1 && logicalOperators.get(i)!='null')
                         {                          
                            strSubSQL = strSubSQL +' ' + logicalOperators.get(i) + ' ';
                         }
                         
                     }
                     else
                     {
                         String nullValue = 'null';
                         if(flag ==0){
                            if(dataTypes.get(i)=='String')
                                strSubSQL = searchFields.get(i)+' ' + searchOperators.get(i) + ' '+ '\''+searchValues.get(i) + '\'';
                            else
                                strSubSQL = searchFields.get(i)+' ' + searchOperators.get(i) + ' '+searchValues.get(i) ;
                         }
                         else{
                             if(dataTypes.get(i)=='String')
                                strSubSQL = strSubSQL + searchFields.get(i)+' ' + searchOperators.get(i) + ' '+ '\''+searchValues.get(i) + '\'';
                              else
                                  strSubSQL = strSubSQL + searchFields.get(i)+' ' + searchOperators.get(i) + ' '+searchValues.get(i) ;
                            }
                         if(i<(logicalOperators.size())-1 && /*!(logicalOperators.get(i).equals(nullValue))*/logicalOperators.get(i)!='null')
                         {
                            strSubSQL = strSubSQL +' '+ logicalOperators.get(i)+ ' ';
                         }
                     }
                     flag = 1;
                     i++;
                }
                return strSubSQL;
            }
            else
            {
                intRetVal = '-1';   
            }
        }
        catch(Exception e)
        {
            System.debug(e.getMessage());
            return null;
        }
        return intRetVal;
        
    } 
   //Start of changes CR 1816825, SHARDUL 
//Creates a XML from the lists

      public String Createxml()    
    { 
        
        {       
                
          Map<String, String> label_api = new map<string, string> ();
         
          for (EBCS_AccountSearchFields__c objAccSearchFields : EBCS_AccountSearchFields__c.getAll().values())
            {
             label_api.put(objAccSearchFields.Name_API__c, objAccSearchFields.Name);            
            }
            
           for (EBCS_ProductSearchFields__c objProdSearchFields : EBCS_ProductSearchFields__c.getAll().values())
            {
             label_api.put(objProdSearchFields.Name_API__c, objProdSearchFields.Name);            
            }
            
              
            label_api.put('=','Equals');
            label_api.put('!=','Not Equals');
            label_api.put('%','Contains');
            label_api.put(') AND (', 'AND');
            label_api.put('OR', 'OR');

            
          XmlStreamWriter w = new XmlStreamWriter();
         // w.writeStartDocument(null, '1.0');
         // w.writeStartElement(null, 'SearchCriteria', null);          
          Integer i=0;
          
          for(i=0;i<searchFields.size();i++)
          {
              w.writeStartElement(null, 'row', null);
              w.writeStartElement(null,'Field',null);
              
              if(label_api.get(searchFields[i])!= null)
                  {
                  w.writeCharacters(label_api.get(searchFields[i]));
                  }
              
              w.writeEndElement();
              
              w.writeStartElement(null,'Operator',null);
              
              if(label_api.get(searchOperators[i])!= null)
                  {
                  w.writeCharacters(label_api.get(searchOperators[i]));
                  }
              
              
              w.writeEndElement();
              
              w.writeStartElement(null,'Value',null);
              
              w.writeCharacters(searchValues[i]);
                
              w.writeEndElement();
             
              w.writeStartElement(null,'LogicalOperator',null);
              
              if (logicalOperators.get(i)!= null && i < (searchFields.size()-1) )
              {
               if(label_api.get(logicalOperators[i])!= null)
                  {
                  w.writeCharacters(label_api.get(logicalOperators[i]));
                  }
              }
              
              w.writeEndElement();
             
              w.writeEndElement(); //end row
              //System.assertNotEquals( w.getXmlString(),null);
          }
         
          
          
         // w.writeEndElement(); //end library
         // w.writeEndDocument();
          xmlOutput = w.getXmlString();
          w.close();
          return xmlOutput;
        }
        
    }
//End of changes CR 1816825, SHARDUL
}