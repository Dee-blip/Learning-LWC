/*
Author: Jayalakshmi A
Description: This class essentially builds SOQLs when TableName and Where clause are given as Inputs
EnhancedSoqlBuilder is an extension of this class and provides more features
*/
public virtual class EB_SoqlBuilder
{
    public List<String> searchFields = new List<String>();
    public List<String> searchOperators = new List<String>();
    public List<String> searchValues = new List<String>();
    public List<String> logicalOperators = new List<String>();
    public String strWhereClause;
    public String strSQL;
    public String tableName; 
    public String strSelectSOQL;
    public String strSubSQL;
    public String strTemp; 
     public String xmlOutput;
    
    //constructor
    public EB_SoqlBuilder()
    {
        strWhereClause = '';
        strSQL = '';
        tableName = '';
    }
     
    //getter and setter methods for tableName
    public String getTableName()
    {        
        return tableName;    
    }        
    public void setTableName(String name)
    {          
        tableName = name;    
    }   
    
    //clears all the lists    
    public virtual void  clearSearchCriteria()    
    {
        try
        {        
            searchFields.clear();        
            searchOperators.clear();        
            searchValues.clear();       
            logicalOperators.clear();  
        } 
        catch(Exception e)
        {
            System.debug(e.getMessage());
        } 
    }
    
    public virtual void addSearchCriteria(String searchField, String searchOperator, String searchValue, String logicalOperator)    
    { 
        try
        {       
            searchFields.add(searchField);        
            searchOperators.add(searchOperator);        
            searchValues.add(searchValue);          
            logicalOperators.add(logicalOperator); 
        }
        catch(Exception e)
        {
            System.debug(e.getMessage());
        }   
    }
    
    public virtual void removeSearchCriteria(String searchField, String searchOperator, String searchValue)
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
                }        
            } 
        }
        catch(Exception e)
        {
            System.debug(e.getMessage());
        }   
    }
    
    public virtual String buildSelectClause()
    {  
        try
        {      
            strSelectSOQL = 'SELECT Id FROM ' + tableName + ' where ';
        } 
        catch(Exception e)
        {
            System.debug(e.getMessage());
            return null;
        }
        return strSelectSOQL;  
    }
    
    public virtual String buildWhereClause()
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
                         if(flag ==0)
                            strSubSQL = searchFields.get(i) + ' LIKE '+ '\'' + '%' + searchValues.get(i)+'%' + '\'';
                         else
                            strSubSQL = strSubSQL + searchFields.get(i) + ' LIKE '+ '\'' + '%' + searchValues.get(i)+'%'+ '\'';
                         if(i<(logicalOperators.size())-1 && logicalOperators.get(i)!='null')
                         {                          
                            strSubSQL = strSubSQL +' ' + logicalOperators.get(i) + ' ';
                         }
                         
                     }
                     else
                     {
                         String nullValue = 'null';
                         if(flag ==0)
                         {
                            //System.assertNotEquals(searchFields.get(i),null);
                            strSubSQL = searchFields.get(i)+' ' + searchOperators.get(i) + ' '+ '\''+searchValues.get(i) + '\'';
                         }
                         else
                            strSubSQL = strSubSQL + searchFields.get(i)+' ' + searchOperators.get(i) + ' '+ '\''+searchValues.get(i) + '\'';
                         if(i<(logicalOperators.size())-1 && logicalOperators.get(i)!='null')
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
    
    public String buildSQL(String whereClause)
    {        
        strSQL = '';    
        try
        {              
            strSQL = strSelectSOQL + ' '  + whereClause;       
        }
        catch(Exception e)
        {
            System.debug(e.getMessage());
            return null;
        }               
        return strSQL;    
    }

}