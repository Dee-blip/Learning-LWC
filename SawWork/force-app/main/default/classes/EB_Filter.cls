//Modified by ssawhney for CR 2012122 - Enable the search page to navigate directly to an Incident record if incident number is provided
public virtual class EB_Filter extends SI_ComponentControllerBase {
  
 
  
  //The Attributes of the Component   
  public Integer LimitSOQL{get;set;}  
  public EB_FilterObject fieldSet {get;set;}  
  public List<EB_FilterObject.FieldObject> listOfFields {get;set;}
  public String DefaultSortOrderDirection { get; set; }  
  public String DefaultOrderBy { get; set; }
  public String InputQuery { get; set; }
  public String ReRenderIds {get;set;}
  public String Status {get;set;}
  
  
  //The Property which is accesed to get the outputQuery  
  public String OutputQuery { get{  
  return getOutputQuery();
  } set; }
  

  
  private String ConcatenatedQuery='';
 
 
  
 
   public String sortOrder {
    get  { if (sortOrder == null) {  if ( DefaultSortOrderDirection == null ) { sortOrder = 'asc'; } else { sortOrder = DefaultSortOrderDirection; } } return sortOrder;  }
    set;
  }
 
  // the current field to sort by. defaults to last name
  public String sortField {
    get  { if (sortField == null) { if(DefaultOrderBy == null) { sortField = 'name'; } else { sortField = DefaultOrderBy; } } return sortField;  }
    set;
  }
  
    public String Title {
    get {if (Title == null) {Title = 'Quick Find'; } return Title ;}
    set;
  }
 
  // format the soql for display on the visualforce page
 
  Protected String strLikesearch = '';
 

 
 //This is a property called by a javascript when the Component loads,basically a init.(Constructor didnt work).

  public void getInit() {
    
      OutputQuery = InputQuery;

     listOfFields = fieldSet.fieldObjects;
    
  }
  
  public EB_Filter()
  {
  
      
  }

 /*
    Author: Vineet
  
    Description: THis Function is called on CLick of the Apply Filter Button. it builds the Flitler Like CLause
    
    Modification History: 
    1. Modified by ssawhney for CR 2012122 - Changed the method to virtual and return type to Page Reference
    
 */
  public virtual PageReference ApplyFilter() {
 
    Integer i=0;
  
  
    strLikesearch = '';
    for(i=0;i<listOfFields.size();i++)
    {   
       
         try{
        strLikeSearch+=CreatingWhereClause(listOfFields[i]);
        
        }
        
        catch(Exception e)
        {
        }
       
         
         
    }
       if(!InputQuery.contains('where')&&strLikeSearch !='')
        {
           strLikeSearch = strLikeSearch.removeStart(' and ');
           strLikeSearch = 'where ' + strLikeSearch;
        }
      pageController.PostProcessApplySearch();
      return null; 
  }
 
  // label api dataType advancedSearch BooleanTrueCondition TextboxValueInteger CheckboxValue Dateboxa Dateboxb
  //This is the Core function of this class which build the query.
 private String CreatingWhereClause(EB_FilterObject.FieldObject fo)
 {
     String returnString='';
    
    
     if(fo.DataType =='String' && (fo.TextboxValue!=null && fo.TextboxValue!='' ))
     { 
      fo.TextboxValue = fo.TextboxValue.toLowerCase();
        // system.assertEquals(fo.TextboxValue, 'kk');  
             Boolean Nt;   
           
            
                 if(fo.advancedSearch)
                {
                    
                    List<String> splittedValues;
                    String Operator;
                    if(fo.TextboxValue.contains(' and '))
                    {                       
                        splittedValues = fo.TextboxValue.split(' and ');
                        Operator = ' and ';
                        if(fo.TextboxValue.contains(' or '))
                        {
                         Operator = '---';   
                        }
                    }
                    else
                    {
                    
                        splittedValues = fo.TextboxValue.split(' or ');
                        Operator = ' or ';
                    }
                                       
                  
                    if(Operator!='---')
                    {
                    String tempString = ' and ( ';
                    for(String sp :splittedValues)
                    {   
                        Nt = false;
                        String splitValue = sp.Trim();
                        if(splitValue.startsWith('<>'))
                        {
                            splitValue = splitValue.substring( 2, splitValue.length());
                            Nt = true;
                            tempString += '( NOT ';
                        }
                        splitValue = splitValue.Trim();
                        if( splitValue.contains('*'))
                        {
                            splitValue = splitValue.replace('*','%');
                            tempString +=  fo.api + ' Like \''+ String.escapeSingleQuotes(splitValue) + '\'' ;
                        }
                        else
                        {
                            tempString +=   fo.api + ' = \''+ String.escapeSingleQuotes(splitValue) + '\'' ;  
                        }
                        if(Nt)
                        {
                            tempString += ' ) ' + Operator;
                        }
                        else
                        {
                        
                        tempString += Operator;
                        }
                     }
                     if(tempString.endsWith(Operator))
                     {
                         tempString = tempString.substring(0,tempString.length()-Operator.length());
                     }
                     
                   
                       returnString =  tempString + ' ) ';
                    }
                }
                else
                {
                if(fo.TextboxValue.contains('*'))
                {
                    fo.TextboxValue = fo.TextboxValue.replace('*','%');
                    returnString += ' and ' + fo.api + ' Like \''+ String.escapeSingleQuotes(fo.TextboxValue) + '\'';  
                }
                else
                {
                    returnString += ' and ' + fo.api + ' = \''+ String.escapeSingleQuotes(fo.TextboxValue) + '\'';  
                }
                 
                }
     }     
     else if(fo.DataType.equalsIgnoreCase('Integer') && (fo.TextboxValue!=null && fo.TextboxValue!='' ))
     {
          if(fo.advancedSearch)
          {
                  Boolean Nt;  
                List<String> splittedValues;
                    String Operator;
                    if(fo.TextboxValue.contains(' and '))
                    {                       
                        splittedValues = fo.TextboxValue.split(' and ');
                        Operator = ' and ';
                        if(fo.TextboxValue.contains(' or '))
                        {
                         Operator = '---';   
                        }
                    }
                    else
                    {
                    
                        splittedValues = fo.TextboxValue.split(' or ');
                        Operator = ' or ';
                    }
                                       
                  
                    if(Operator!='---')
                    {
                    String tempString = ' and ( ';
                    for(String sp :splittedValues)
                    {   
                        Nt = false;
                        String splitValue = sp.Trim();
                        if(splitValue.startsWith('<>'))
                        {
                            splitValue = splitValue.substring( 2, splitValue.length());
                            Nt = true;
                            tempString += '( NOT ';
                        }
                        splitValue = splitValue.Trim();
                        if( splitValue.contains('>')|| splitValue.contains('<')|| splitValue.contains('>=') || splitValue.contains('<='))
                        {
                            tempString +=  fo.api + string.escapeSingleQuotes(fo.TextboxValue) ;
                           
                        }
                        else
                        {
                            tempString +=   fo.api + ' = '+ string.escapeSingleQuotes(fo.TextboxValue) ;
                            //tempString +=   fo.api + ' = \''+ String.escapeSingleQuotes(splitValue) + '\'' ;  
                        }
                        if(Nt)
                        {
                            tempString += ' ) ' + Operator;
                        }
                        else
                        {
                        
                        tempString += Operator;
                        }
                     }
                     if(tempString.endsWith(Operator))
                     {
                         tempString = tempString.substring(0,tempString.length()-Operator.length());
                     }
                     
                   
                       returnString =  tempString + ' ) ';
                    }
            
         }
         else
         {
            
               if(fo.TextboxValue.contains('>')|| fo.TextboxValue.contains('<')||fo.TextboxValue.contains('>=')||fo.TextboxValue.contains('<='))
                {
                returnString += ' and ' + fo.api + string.escapeSingleQuotes(fo.TextboxValue) ;
                }
                else
                {
                returnString += ' and ' + fo.api + ' = '+ string.escapeSingleQuotes(fo.TextboxValue) ;
                }
            
         }
     }
     else if(fo.DataType == 'date' && ((fo.Dateboxa!=null && fo.Dateboxa!='')||(fo.Dateboxb!=null && fo.Dateboxb!='')))
     {
         try
         {
            if(fo.advancedSearch)
            {
                    if(fo.Dateboxa!=null && fo.Dateboxa!='')
                    returnString += ' and ' + fo.api + ' >= '+ String.ValueOf(date.parse(fo.Dateboxa));
                    if(fo.Dateboxb!=null && fo.Dateboxb!='')
                    returnString += ' and ' + fo.api + ' <= '+ String.ValueOf(date.parse(fo.Dateboxb));  
               
            }
            else
            {
                
                    if(fo.Dateboxa!=null && fo.Dateboxa!='')
                    returnString += ' and ' + fo.api + ' >= '+ String.ValueOf(date.parse(fo.Dateboxa));
                    if(fo.Dateboxb!=null && fo.Dateboxb!='')
                    returnString += ' and ' + fo.api + ' <= '+ String.ValueOf(date.parse(fo.Dateboxb));  
                
            }
          }
          catch(Exception ex)
          {
          }
     } 
     else if(fo.DataType == 'datetime' && ((fo.Dateboxa!=null && fo.Dateboxa!='')||(fo.Dateboxb!=null && fo.Dateboxb!='')))
     {
         try
         {
            if(fo.advancedSearch)
            {
                    if(fo.Dateboxa!=null && fo.Dateboxa!='')
                    returnString += ' and ' + fo.api + ' >= '+ String.ValueOf(date.parse(fo.Dateboxa))+'T00:00:00Z';
                    if(fo.Dateboxb!=null && fo.Dateboxb!='')
                    returnString += ' and ' + fo.api + ' <= '+ String.ValueOf(date.parse(fo.Dateboxb))+'T00:00:00Z';  
               
            }
            else
            {
                
                    if(fo.Dateboxa!=null && fo.Dateboxa!='')
                    returnString += ' and ' + fo.api + ' >= '+ String.ValueOf(date.parse(fo.Dateboxa))+'T00:00:00Z';
                    if(fo.Dateboxb!=null && fo.Dateboxb!='')
                    returnString += ' and ' + fo.api + ' <= '+ String.ValueOf(date.parse(fo.Dateboxb))+'T00:00:00Z';  
                
            }
          }
          catch(Exception ex)
          {
          }
     }
     else if(fo.DataType == 'Boolean' )
     {
     
        if(fo.advancedSearch)
          {
              if(fo.CheckboxValue)
              {  
                  returnString += ' and ' + fo.BooleanTrueCondition;
              }
              else
              {
                    returnString += ' and ' + fo.BooleanFalseCondition;
              }
            
         }
         else
         {
            
                returnString += ' and ' + fo.api + ' = '+ fo.CheckboxValue ;
            
         }
     } 
     else if(fo.DataType == 'Other')
     {
        if(fo.advancedSearch)
        {
            
                queryGeneratorForOtherDT(fo);
            
        }
        else
        {
           
                queryGeneratorForOtherDT(fo);
           
        }
     }
     return returnString ;
 }  
  public virtual string queryGeneratorForOtherDT(EB_FilterObject.FieldObject fo)
  {
  return '';
  }
  
  private String getOutputQuery()
  {
      
      if(!InputQuery.toLowerCase().Contains('limit'))
      ConcatenatedQuery= InputQuery + strLikeSearch + ' Order by ' + SortField + ' ' + SortOrder + ' NULLS LAST limit ' + LimitSOQL ;
      else
      {
       List<String> splitString = InputQuery.split('limit');
       ConcatenatedQuery = splitString[0] + strLikeSearch + ' Order by ' + SortField + ' ' + SortOrder + ' NULLS LAST limit ' + splitString[1] ;
      }
     
      return ConcatenatedQuery;
  }
  
  /*
    Author: Vineet
  
    Description: Clear the Filter
 */
 
   public virtual PageReference clearFilter() 
  {
      strLikeSearch ='';
      SortField = SortOrder =null;
      pageController.clearSearch(); 
      return null;
  
  }
  public void setSortField(String sfield)
  {
      SortField=sfield;
  }
  
  public void toggleSortOrder() {
 
    // simply toggle the direction
    sortOrder = sortOrder.equals('asc') ? 'desc' : 'asc';
    
      pageController.SetObjControllerNull(); 
    
  }
}