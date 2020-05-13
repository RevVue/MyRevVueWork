/**
 *  Description     :   Utility methods to hold the genric methods
 *
 *  Created By      :   
 *
 *  Created Date    :   02/18/2015 
 *
 *  Version         :   V1.0
 *
 *  Revision Log    :   V1.0 - Created
 **/
 public with sharing class Utility { 

    //Variable to check that multiple currency enabled in the organization 
    public  boolean isMultiCurrencyEnabled ;
     
    //Map to hold Exchange rate with respect to currency        
    Map<String , String> mapCISOCOdeToExchangeRate = new Map<String , String>();
    Set<Date> nextDate = new Set<Date>();
    Set<Date> startDate = new Set<Date>();
    //String to hold query        
    String queryStringForExchangeRate = ''; 
    
    //String to hold query
    String queryStringForStaticExchangeRate = ''; 
    
    //List of SObject
    List<Sobject> sObjectsList ;
    
    public Utility(Opportunity opp) {                                        
        
        //Initilize list of sObject
        sObjectsList = new List<Sobject>();
        
        //Checking if multicurrency enabled
        isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
        mapCISOCOdeToExchangeRate  = new Map<String , String>();
        
        //If multi currency enabled in the org then proceed forword
        if(isMultiCurrencyEnabled) {
           
            if(opp != null)
                Date closeDt = opp.CloseDate;
            Date currentDate = Date.Today();
            
            //Checking for the Closed and Won Opportunities
            queryStringForExchangeRate += 'Select IsoCode, ConversionRate, StartDate, NextStartDate From DatedConversionRate WHERE StartDate <=:  closeDt AND NextStartDate >=: closeDt ORDER BY StartDate DESC'; //Query string
            
            //Query string
            queryStringForStaticExchangeRate = 'Select IsoCode, ConversionRate From CurrencyType';
            
            //Query to get the dated exchange rate
            sObjectsList = database.query(queryStringForExchangeRate);
            
            //Checking for size
            if(sObjectsList.size() >0) {
                
                //Loop through sObject type
                for(SObject cType : sObjectsList) {
                    
                    nextDate.add(Date.ValueOf(cType.get('StartDate')));
                    startDate.add(Date.ValueOf(cType.get('NextStartDate')));
                    //Checking for null map and null converss=ion rate
                    if(!mapCISOCOdeToExchangeRate.containsKey(String.ValueOf(cType.get('IsoCode'))) && cType.get('ConversionRate') != null)
                        mapCISOCOdeToExchangeRate.put(String.ValueOf(cType.get('IsoCode')), String.ValueOf(cType.get('ConversionRate')));
                }
            }else { 
                sObjectsList = database.query(queryStringForStaticExchangeRate);
                
                //Loop through sObject type
                for(SObject cType : sObjectsList) {
                    
                    //Checking for null map and null converss=ion rate
                    if(!mapCISOCOdeToExchangeRate.containsKey(String.ValueOf(cType.get('IsoCode'))) && cType.get('ConversionRate') != null)
                        mapCISOCOdeToExchangeRate.put(String.ValueOf(cType.get('IsoCode')), String.ValueOf(cType.get('ConversionRate')));
                }
            }
            
        }   
    }
    
    /**
     *  @Description    :   This method is used to Calculate currency amount into Ex. USD 1000 (EUR 200) like this
     *
     *  @args           :   String oppCurrencyIsoCode , Decimal amount
     *
     *  @return Type    :   String
     **/
    public string calculateAmountInCurrency (String oppCurrencyIsoCode , Decimal amount) {
        
        //String 
        String  formattedAmount = '';
        
        //Today's date  
        Date dt = Date.Today();
        
        //String to hold user's currency
        String userCurrencyIsoCode = userInfo.getDefaultCurrency();
       
        isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
        
        //Checking if currency enabled
        if(isMultiCurrencyEnabled && mapCISOCOdeToExchangeRate != null) {
            
            Decimal decimalAmount = 0.001;
            
            if(amount < 0) 
                decimalAmount = -0.001; 
          
            //Change Amount into default currency 
            Decimal defaultAmount = amount;
            
            if(mapCISOCOdeToExchangeRate.containsKey(oppCurrencyIsoCode))
                defaultAmount =  (amount/Decimal.valueOf(mapCISOCOdeToExchangeRate.get(oppCurrencyIsoCode)));
            
            //User's Aspect amount 
            Decimal usersAmount = defaultAmount;
            
            if(mapCISOCOdeToExchangeRate.containsKey(userCurrencyIsoCode))
            usersAmount = defaultAmount*Decimal.valueOf(mapCISOCOdeToExchangeRate.get(userCurrencyIsoCode)); 
            
            //Ammount to be format 
            String amountFormatted = string.valueOf(amount);
            String s = ( Decimal.valueOf(amountFormatted == null || amountFormatted.trim()== '' ? '0' : amountFormatted).setScale(2) + decimalAmount ).format();
            amountFormatted = s.substring(0, s.length()-1);
            
            //User amount to be formatted
            String userAmountFormatted = string.valueOf(usersAmount);   
            String UAmount = ( Decimal.valueOf(userAmountFormatted == null || userAmountFormatted.trim()== '' ? '0' : userAmountFormatted).setScale(2) + decimalAmount ).format();
            userAmountFormatted = UAmount.substring(0, UAmount.length()-1);
            
            //Checking for Currency code of opportunity  equal to user's iso code
            if(oppCurrencyIsoCode == userCurrencyIsoCode) 
                formattedAmount = oppCurrencyIsoCode + ' ' + amountFormatted;
            else // If differ then format the amount like below    
                formattedAmount = oppCurrencyIsoCode + ' ' + amountFormatted + '<br/>'+' (' + userCurrencyIsoCode + ' ' + userAmountFormatted + ')';
            
            /**** Calculation End here ****/
        }      
        return formattedAmount;  
    } 
     
     /**
     *  @Description    :   This method is used to get current theme of user.
     *
     *  @args           :   
     *
     *  @return Type    :   String
     **/
    public static string getUITheme () {
     
     //Getting Theme from global variable
     String theme = UserInfo.getUiThemeDisplayed();
     
        //Return theme
        return theme;
    }
     
    /**
     *  @Description    :   This method is used to Calculate currency amount back to the default amount.
     *
     *  @args           :   String oppCurrencyIsoCode, String calculationCurrenceyCode Decimal amount
     *
     *  @return Type    :   Decimal
     **/
     public String AmtWithDefaultCurrency (String oppCurrencyIsoCode, String calculationCurrenceyCode, Decimal amount) {

        //String 
        String  formattedAmount = '';
        //Today's date  
        Date dt = Date.Today();
        isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
        
        //Checking if currency enabled
        if(isMultiCurrencyEnabled && mapCISOCOdeToExchangeRate != null) {
            
            Decimal decimalAmount = 0.001;
            
            if(amount < 0) 
                decimalAmount = -0.001; 
          
            //Change Amount into default currency 
            Decimal defaultAmount = amount;
            
            if(mapCISOCOdeToExchangeRate.containsKey(oppCurrencyIsoCode))
                defaultAmount =  (amount/Decimal.valueOf(mapCISOCOdeToExchangeRate.get(oppCurrencyIsoCode)));
            
            //User's Aspect amount 
            Decimal usersAmount = defaultAmount;
            
            if(mapCISOCOdeToExchangeRate.containsKey(calculationCurrenceyCode))
            usersAmount = defaultAmount*Decimal.valueOf(mapCISOCOdeToExchangeRate.get(calculationCurrenceyCode)); 
            
            //Ammount to be format 
            String amountFormatted = string.valueOf(amount);
            String s = ( Decimal.valueOf(amountFormatted == null || amountFormatted.trim()== '' ? '0' : amountFormatted).setScale(2) + decimalAmount ).format();
            amountFormatted = s.substring(0, s.length()-1);
            
            //User amount to be formatted
            String userAmountFormatted = string.valueOf(usersAmount);   
            String UAmount = ( Decimal.valueOf(userAmountFormatted == null || userAmountFormatted.trim()== '' ? '0' : userAmountFormatted).setScale(2) + decimalAmount ).format();
            userAmountFormatted = UAmount.substring(0, UAmount.length()-1);
            
            //Checking for Currency code of opportunity  equal to user's iso code
            if(oppCurrencyIsoCode == calculationCurrenceyCode) 
                formattedAmount = oppCurrencyIsoCode + ' ' + amountFormatted;
            else // If differ then format the amount like below    
                formattedAmount = oppCurrencyIsoCode + ' ' + amountFormatted + '<br/>'+' (' + calculationCurrenceyCode + ' ' + userAmountFormatted + ')';
            
            /**** Calculation End here ****/
        }      
        return formattedAmount;  
     }
     
     /**
     *  @Description    :   This method is used to get corporate currency.
     *
     *  @args           :   
     *
     *  @return Type    :   Decimal
     **/
    public Decimal corporateCurrencyCalculation (String oppCurrencyIsoCode, Decimal amount) {
        
        isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
        
        //Checking if currency enabled
        if(isMultiCurrencyEnabled && mapCISOCOdeToExchangeRate != null) {
             
            if(mapCISOCOdeToExchangeRate.containsKey(oppCurrencyIsoCode))
                amount = (amount/Decimal.valueOf(mapCISOCOdeToExchangeRate.get(oppCurrencyIsoCode)));
            
        }      
        return amount;  
    }
     
     /**
     *  @Description    :   This method is used to check the object permission.
     *
     *  @args           :   String, String   
     *
     *  @return Type    :   Boolean
     **/
    public static Boolean checkObjectPermission(String permissionType, String objectName) {
        
        DescribeSObjectResult sobjectDetails;
        
        if(String.isNotblank(Constants.currentPackagePrefix)){
           
            //Custom object check
            if(objectName.contains('__c'))
                sobjectDetails = Schema.getGlobalDescribe().get(Constants.currentPackagePrefix + '__'  + objectName).getDescribe();
            else
                sobjectDetails = Schema.getGlobalDescribe().get(objectName).getDescribe();
		}else
        	sobjectDetails = Schema.getGlobalDescribe().get(objectName).getDescribe();
        
        //Check field in map
        if(permissionType == Constants.PERMISSION_ACCESS && sobjectDetails.isAccessible())
            return true;
        
        //Check field in map
        if(permissionType == Constants.PERMISSION_QUERYABLE && sobjectDetails.isQueryable())
            return true;
                
        //Check field in map
        if(permissionType == Constants.PERMISSION_CREATE && sobjectDetails.isCreateable())
            return true;    
        
        //Check field in map
        if(permissionType == Constants.PERMISSION_UPDATE && sobjectDetails.isUpdateable())
            return true;
		
		if(permissionType == Constants.PERMISSION_DELETE && sobjectDetails.isDeletable())
            return true;
        
        if(permissionType == Constants.PERMISSION_UPSERT && (sobjectDetails.isCreateable() || sobjectDetails.isUpdateable()))
            return true;
            
        return false;
    }
     
     /**
      * @Description    :   This method is used to check field permission
      *
      * @argument       :   Map<String, Schema.DescribeFieldResult>, String, String 
      *
      * @Return Type    :   Boolean
      *
      **/
      public static Boolean checkFieldPermission(Map<String, Schema.DescribeFieldResult> sobjectFields, String fieldName, String permissionType) {
        
        fieldName = fieldName.trim().toLowerCase();
        
        if(!sobjectFields.containsKey(fieldName) && sobjectFields.containsKey(Constants.currentPackagePrefix.toLowerCase() + '__' + fieldName))
            fieldName = Constants.currentPackagePrefix + '__' + fieldName;
        
        fieldName = fieldName.trim().toLowerCase();  
           
        //Check field in map
        if(permissionType == Constants.PERMISSION_UPDATE && sobjectFields.containsKey(fieldName) && sobjectFields.get(fieldName).isUpdateable())
            return true;
            
        //Check field in map
        if(permissionType == Constants.PERMISSION_CREATE && sobjectFields.containsKey(fieldName) && sobjectFields.get(fieldName).isCreateable())
            return true;    
            
        //Check field in map
        if(permissionType == Constants.PERMISSION_ACCESS && sobjectFields.containsKey(fieldName) && sobjectFields.get(fieldName).isAccessible())
            return true;
          
        //Check field in map
          if(permissionType == Constants.PERMISSION_UPSERT && ((sobjectFields.containsKey(fieldName) && sobjectFields.get(fieldName).isCreateable()) || (sobjectFields.containsKey(fieldName) && sobjectFields.get(fieldName).isUpdateable())))
           return true;
        
        //Check for Contains check
        if(permissionType == Constants.MAP_CONTAINS && sobjectFields.containsKey(fieldName))
            return true;
        
        return false;
    }
     
     /**
      * @Description    :   This method is used to get field permission
      *
      * @argument       :   Map<String, Schema.DescribeFieldResult>, String, String 
      *
      * @Return Type    :   Boolean
      *
      **/
    public static Map<String,Schema.Describefieldresult> getFieldPermissions(String sobjectName) {
        
        //Map used to hold the fields result
        Map<String, Schema.SobjectField> mapSobjectfields = new Map<String, Schema.SobjectField>();
       
        if(String.isNotblank(Constants.currentPackagePrefix) && !sobjectName.contains(Constants.currentPackagePrefix)){
          
            //Custom object check
            if(sobjectName.contains('__c')){
                mapSobjectfields = Schema.getGlobalDescribe().get(Constants.currentPackagePrefix + '__'  + sobjectName).getDescribe().fields.getMap();
            }
            else{
                mapSobjectfields = Schema.getGlobalDescribe().get(sobjectName).getDescribe().fields.getMap();
            }
        }
        else{
                mapSobjectfields = Schema.getGlobalDescribe().get(sobjectName).getDescribe().fields.getMap();
        }

        //Map used to hold the fields details
        Map<String,Schema.Describefieldresult> mapFieldDetails = new Map<String, Schema.Describefieldresult>();
        
        for(String fieldName : mapSobjectfields.Keyset()) {
            Schema.Sobjectfield field = mapSobjectfields.get(fieldname);
           
            mapFieldDetails.put(String.valueOf(field).toLowerCase(),field.getDescribe());
            
        }
        if(mapFieldDetails.size() > 0)
            return mapFieldDetails;
        return new Map<String, Schema.DescribeFieldResult>();
    }
 }