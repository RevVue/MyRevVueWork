public without sharing class RevRecHelper {
    public static Boolean SendEmail(string messageBody) {
        Boolean success = true;
        try {
            Messaging.reserveSingleEmailCapacity(2);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {'steve.bi@gmail.com'}; 
            String[] ccAddresses = new String[] {'bi_steve@hotmail.com'};
            mail.setToAddresses(toAddresses);
            mail.setCcAddresses(ccAddresses);
            
            string org = 'Org:' + UserInfo.getOrganizationName()+ ', User:' + UserInfo.getUserName();
            mail.setSubject('RevRec Schedular for ' + org);
    
            mail.setBccSender(false);
            mail.setUseSignature(false);
            mail.setPlainTextBody(messageBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } Catch (Exception exp) {
            success = false;
        }
        return success;
    }

    public static list<Opportunity> GetOpportunityWithAllFieldsByIdSet(Set<Id> Ids) {
        String objectName = 'Opportunity'; 
        String query = 'SELECT';
        list<Opportunity> result = null;
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
    
        for(String s : objectFields.keySet()) {   query += ' ' + s + ',';}
        
        // Strip off the last comma if it exists.
        if (query.subString(query.Length()-1,query.Length()) == ','){    query = query.subString(0,query.Length()-1);}
        
        query += ' FROM ' + objectName;
        query += ' WHERE Id IN :Ids';
        
        System.debug('@@@@ query ' +query);
        try {        
            result = database.query(query);
            
        } catch (QueryException e){ 
            //do nothing
            System.debug('@@@@@&&&&&&&& error' +e.getMessage());
        }
        
        return result;
    }

    public static Opportunity GetOpportunityWithAllFieldsById(ID id) {
        String objectName = 'Opportunity';
        String query = 'SELECT';
        Opportunity result = null;
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        for(String s : objectFields.keySet()) {   query += ' ' + s + ',';}
        
        // Strip off the last comma if it exists.
        if (query.subString(query.Length()-1,query.Length()) == ','){    query = query.subString(0,query.Length()-1);}
        
        query += ' FROM ' + objectName;
        query += ' WHERE Id = :id';
        
        try {        
            result = database.query(query);
            
        } catch (QueryException e){ 
            //do nothing
            System.debug('@@@@@^^^^^^^^^^ error' +e.getMessage());
        }
        
        return result;
    }
    public static list<OpportunityLineItem> GetLineItemListWithAllFieldsByOpportunityIdSet(Set<Id> oppIds) {
        String objectName = 'OpportunityLineItem';
        String query = 'SELECT';
        list<OpportunityLineItem> result = null;
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
    
        for(String s : objectFields.keySet()) {   query += ' ' + s + ',';}
        
        // Strip off the last comma if it exists.
        if (query.subString(query.Length()-1,query.Length()) == ','){    query = query.subString(0,query.Length()-1);}
        
        query += ' FROM ' + objectName;
        query += ' WHERE OpportunityId IN :oppIds';
        
        try {        
            result = database.query(query);
            
        } catch (QueryException e){ 
            //do nothing
            System.debug('@@@@@%%%%%%%%% error' +e.getMessage());
        }
        
        return result;
    }

    public static sObject SelectAllFieldsForObject(String objectName, string Id) {
        
        System.debug('@@@@ @@@@@@@@@');
        String query = 'SELECT';
        sObject result = null;
       
    	Boolean isMultiCurrencyEnable = UserInfo.isMultiCurrencyOrganization();
    	Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
    	Set<String> setQueryField = new Set<String>();
        
        for(String s : objectFields.keySet()) {   
        	
        	s = s.toLowerCase().trim();
            
        	//if(objectFields.get(s).getDescribe().isAccessible() && objectFields.get(s).getDescribe().isUpdateable() && objectFields.get(s).getDescribe().isCreateable()) {
        		if(!setQueryField.contains(s)) {
		    		
		    		if(s != 'syncedquoteid') {
		    			if(isMultiCurrencyEnable)
			    			query += ' ' + s + ',';
			        	else
			        		query += ' ' + s + ',';
		    		}
		        		
		        	setQueryField.add(s);
		    	}
        	//}
        }
        
        // Strip off the last comma if it exists.
        if (query.subString(query.Length()-1,query.Length()) == ','){    query = query.subString(0,query.Length()-1);}
        
	        query += ' FROM ' + objectName;
        query += ' WHERE id = \'' + id + '\'';
        
        System.debug('@@@@ query ' +query);
        try {        
            result = database.query(query);
        } catch (QueryException e){  
            //do nothing
            System.debug('@@@@@$$$$$$$$ error' +e.getMessage());
        }
        
        return result;
    }

    public static OpportunityLineItem  GetLineItemWithAllFeilds(string lineItemId) {
        String objectName = 'OpportunityLineItem';
        String query = 'SELECT';
        OpportunityLineItem result = null;
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
    
        for(String s : objectFields.keySet()) {   query += ' ' + s + ',';}
        
        // Strip off the last comma if it exists.
        if (query.subString(query.Length()-1,query.Length()) == ','){    query = query.subString(0,query.Length()-1);}
        
        query += ' FROM ' + objectName;
        query += ' WHERE Id = \'' + lineItemId + '\'';
        
        try {        
            result = database.query(query);
        } catch (QueryException e){ 
            //do nothing
            System.debug('@@@@@!!!!!!!!!!!! error' +e.getMessage());
        }
        
        return result;
    }
	
	 public static Product2  GetProduct2WithAllFeilds(string product2Id) {
        String objectName = 'Product2';
        String query = 'SELECT';
        Product2 result = null;
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
    
        for(String s : objectFields.keySet()) {   query += ' ' + s + ',';}
        
        // Strip off the last comma if it exists.
        if (query.subString(query.Length()-1,query.Length()) == ','){    query = query.subString(0,query.Length()-1);}
        
        query += ' FROM ' + objectName;
        query += ' WHERE Id = \'' + product2Id + '\'';
        
        try {        
            result = database.query(query);
        } catch (QueryException e){ 
            //do nothing
            System.debug('@@@@@####### error' +e.getMessage());
        }
        
        return result;
    }
	
    public static list<OpportunityLineItem> GetLineItemListWithAllFeilds(string oppId) {
        String objectName = 'OpportunityLineItem';
        String query = 'SELECT';
        list<OpportunityLineItem> result = null;
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
    
        for(String s : objectFields.keySet()) {   query += ' ' + s + ',';}
        
        // Strip off the last comma if it exists.
        if (query.subString(query.Length()-1,query.Length()) == ','){    query = query.subString(0,query.Length()-1);}
        
        query += ' FROM ' + objectName;
        query += ' WHERE OpportunityId = \'' + oppId + '\'';
        
        try {        
            result = database.query(query);
            
        } catch (QueryException e){ 
            //do nothing
            System.debug('@@@@@11_!1_1_! error' +e.getMessage());
        }
        return result;
    }
    
    public static list<OpportunityLineItem> GetLineItemListWithAllFieldsByItemSet(Set<Id> LineItemIds) {
        String objectName = 'OpportunityLineItem';
        String query = 'SELECT';
        list<OpportunityLineItem> result = null;
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
    
        for(String s : objectFields.keySet()) {   query += ' ' + s + ',';}
        
        // Strip off the last comma if it exists.
        if (query.subString(query.Length()-1,query.Length()) == ','){    query = query.subString(0,query.Length()-1);}
        
        query += ' FROM ' + objectName;
        query += ' WHERE Id IN :LineItemIds';
        
        try {        
            result = database.query(query);
            
        } catch (QueryException e){ 
            //do nothing
            System.debug('@@@@@10101010 error' +e.getMessage());
        }
        System.debug('@@@ result' +result);
        return result;
    }
    
	public static list<OpportunityLineItem> GetLineItemListWithAllFieldsByItemSetClone(Set<Id> LineItemIds) {
        String objectName = 'OpportunityLineItem';
        String query = 'SELECT';
        list<OpportunityLineItem> result = null;
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
    
        for(String s : objectFields.keySet()) {   query += ' ' + s + ',';}
        
        // Strip off the last comma if it exists.
        if (query.subString(query.Length()-1,query.Length()) == ','){    query = query.subString(0,query.Length()-1);}
        
        query += ' ,PricebookEntry.product2.Name , PricebookEntry.product2.Id, Opportunity.AccountId, Opportunity.StageName ';
        query += ' FROM ' + objectName;
        query += ' WHERE Id IN :LineItemIds';
        
        try {        
            result = database.query(query);
            
        } catch (QueryException e) { //do nothing 
        	System.debug('@@@@@99999 error' +e.getMessage());
        }
        
        return result;
    }
	
	public static list<Product2> GetProduct2ListWithAllFieldsByItemSetClone(Set<Id> setProduct2Ids) {
        String objectName = 'Product2';
        String query = 'SELECT';
        list<Product2> result = null;
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
    
        for(String s : objectFields.keySet()) {   query += ' ' + s + ',';}
        
        // Strip off the last comma if it exists.
        if (query.subString(query.Length()-1,query.Length()) == ','){    query = query.subString(0,query.Length()-1);}
        
        //query += ' ,PricebookEntry.product2.Name , PricebookEntry.product2.Id, Opportunity.AccountId, Opportunity.StageName ';
        query += ' FROM ' + objectName;
        query += ' WHERE Id IN :setProduct2Ids';
        
        try {        
            result = database.query(query);
            
        } catch (QueryException e){ 
            //do nothing
            System.debug('@@@@@88888 error' +e.getMessage());
        }
        
        return result;
    }
    public static Map<String, String> getAllOpportunityFieldsWithDateType() {
        Map<string, string> result = new Map<string, string>();
        Map<String, Schema.SObjectField> M = Schema.SObjectType.Opportunity.fields.getMap(); 
        for (Schema.SObjectField item: m.values()){
            Schema.Describefieldresult theField = item.getDescribe();
            if (theField.getType() == Schema.DisplayType.Date) {
                result.put('OPPORTUNITY:' + theField.getName(), 'OPPORTUNITY:' + theField.getLabel());
            }
        }

        Map<String, Schema.SObjectField> oppLineItems = Schema.SObjectType.OpportunityLineItem.fields.getMap(); 
        for (Schema.SObjectField item: oppLineItems.values()){
            Schema.Describefieldresult theField = item.getDescribe();
            if (theField.getType() == Schema.DisplayType.Date) {
                result.put('OPPORTUNITY PRODUCT:' + theField.getName(), 'OPPORTUNITY PRODUCT:' + theField.getLabel());
            }
        }
        
        Map<String, Schema.SObjectField> mapNameWithProduct2 = Schema.SObjectType.Product2.fields.getMap(); 
        for (Schema.SObjectField item: mapNameWithProduct2.values()){
            Schema.Describefieldresult theField = item.getDescribe();
            if (theField.getType() == Schema.DisplayType.Date) 
                result.put('PRODUCT:' + theField.getName(), 'PRODUCT:' + theField.getLabel());
        }
        
        //---------------------Code added - 09/10/2018 - Add Contract Dates related to Opportunity
        Map<String, Schema.SObjectField> mapNameWithContract = Schema.SObjectType.Contract.fields.getMap(); 
        for (Schema.SObjectField item: mapNameWithContract.values()){
            Schema.Describefieldresult theField = item.getDescribe();
            if (theField.getType() == Schema.DisplayType.Date) 
                result.put('CONTRACT:' + theField.getName(), 'CONTRACT:' + theField.getLabel());
        }
        return result;
    }

    public static Date GetDateByCertainWeekCertainDayOfWeek(Date theDate, String certainWeek, String certainDayOfWeek) {
        Date result = null;  
        Date theFirstDayOfMonth = theDate.toStartOfMonth();
        Integer weekDayOfFirstDayOfMonth = math.MOD(DATE.newInstance(1900, 1, 6).daysBetween(theFirstDayOfMonth), 7);
        Integer inputWeekday = 0; // 0, "Saturday", 1, "Sunday", 2, "Monday", 3, "Tuesday", 4, "Wednesday", 5, "Thursday", 6, "Friday"
        if (certainDayOfWeek == 'saturday') {
            inputWeekday = 0;
        } else if (certainDayOfWeek == 'sunday') {
            inputWeekday = 1;
        } else if (certainDayOfWeek == 'monday') {
            inputWeekday = 2;
        } else if (certainDayOfWeek == 'tuesday') {
            inputWeekday = 3;
        } else if (certainDayOfWeek == 'wednesday') {
            inputWeekday = 4;
        } else if (certainDayOfWeek == 'thursday') {
            inputWeekday = 5;
        } else if (certainDayOfWeek == 'friday') {
            inputWeekday = 6;
        } 
        Date weekDayOfFirstWeek = (inputWeekday >= weekDayOfFirstDayOfMonth ) ? theFirstDayOfMonth.addDays(inputWeekday - weekDayOfFirstDayOfMonth) : theFirstDayOfMonth.addDays(7 - (weekDayOfFirstDayOfMonth - inputWeekday));
        if (certainWeek == '1st') 
            result = weekDayOfFirstWeek;
        else if (certainWeek == '2nd')
            result = weekDayOfFirstWeek.addDays(7);     
        else if (certainWeek == '3rd')
            result = weekDayOfFirstWeek.addDays(14);
        else if (certainWeek == '4th')
            result = weekDayOfFirstWeek.addDays(21);
        else if (certainWeek == 'Last'){
            if(theFirstDayOfMonth.monthsBetween(weekDayOfFirstWeek.addDays(28)) > 0) 
                result = weekDayOfFirstWeek.addDays(21);
            else
                result = weekDayOfFirstWeek.addDays(28);
        }   
        return result;
    }

    //check security access for REVview user, if no access, return the object name
    public static string HasUserLevelAccessForREVview(){
        if (!Schema.SObjectType.Opportunity.isAccessible())
            return 'Opportunity';
        if (!Schema.SObjectType.OpportunityLineItem.isAccessible())
            return 'OpportunityLineItem';
        if (!Schema.SObjectType.RevRecAppSetting__c.isAccessible())
            return 'RevRecAppSetting__c';
        if (!Schema.SObjectType.RevRecOpportunityLineItem__c.isAccessible())
            return 'RevRecOpportunityLineItem__c';
        if (!Schema.SObjectType.RevRecOpportunityLineItemSchedule__c.isAccessible())
            return 'RevRecOpportunityLineItemSchedule__c';
        if (!Schema.SObjectType.RevRecProductRule__c.isAccessible())
            return 'RevRecProductRule__c';
        if (!Schema.SObjectType.RevRecProductRuleMilestone__c.isAccessible())
            return 'RevRecProductRuleMilestone__c';
        if (!Schema.SObjectType.RevRecRules__c.isAccessible())
            return 'RevRecRules__c';
        if (!Schema.SObjectType.RevRecRuleMilestone__c.isAccessible())
            return 'RevRecRuleMilestone__c';
        if(!Schema.SObjectType.RevView_Error_Log__c.isAccessible())
        	return 'RevView_Error_Log__c';
        if(!Schema.SObjectType.RevRecScheduleCategory__c.isAccessible())
        	return 'RevRecScheduleCategory__c';
        if(!Schema.SObjectType.RevRecRuleCategory__c.isAccessible())
        	return 'RevRecRuleCategory__c';
        if(!Schema.SObjectType.RevRecProductRuleCategory__c.isAccessible())
        	return 'RevRecProductRuleCategory__c';
        return '';
    }

    public static string HasAdminLevelAccessForREVview(){return '';}
    
    public static Integer TotalMonthDifference(Date sStartDate, Date sEndDate) {
        Integer intReturn = 0;
        boolean sameMonth = false;
        
        if (sEndDate < sStartDate) return intReturn;

        Integer dayOfMonth = sStartDate.Day(); //captures the month of day for when it adds a month and doesn't have that many days
        Integer daysinMonth = 0; //used to caputre how many days are in the month

        while (sEndDate > sStartDate) //while Other date is still under the other
        {
            sStartDate = sStartDate.AddMonths(1); //as we loop, we just keep adding a month for testing

            daysinMonth = Date.daysInMonth(sStartDate.Year(), sStartDate.Month()); //grabs the days in the current tested month

            if (sStartDate.Day() != dayOfMonth) //Example 30 Jan 2013 will go to 28 Feb when a month is added, so when it goes to march it will be 28th and not 30th
            {
                if (daysinMonth < dayOfMonth) // uses day in month max if can't set back to day of month
                    sStartDate.AddDays(daysinMonth - sStartDate.Day());
                else
                    sStartDate.AddDays(dayOfMonth - sStartDate.Day());
            }

            if (((sEndDate.Year() == sStartDate.Year()) && (sEndDate.Month() == sStartDate.Month()))) //If the loop puts it in the same month and year
            {
                if (sEndDate.Day() >= dayOfMonth) //check to see if it is the same day or later to add one to month
                    intReturn++;
                sameMonth = true; //sets this to cancel out of the normal counting of month
            }
            if ((!sameMonth)&&(sEndDate > sStartDate))//so as long as it didn't reach the same month (or if i started in the same month, one month ahead, add a month)
                intReturn++;
        }
        return intReturn + 1 ;
    }
    
    //---------------------------------------
    public static list<Contract> GetContractListWithAllFieldsByItemSetClone(Set<Id> setContractIds) {
        String objectName = 'Contract';
        String query = 'SELECT';
        list<Contract> result = null;
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
    
        for(String s : objectFields.keySet()) {   query += ' ' + s + ',';}
        
        // Strip off the last comma if it exists.
        if (query.subString(query.Length()-1,query.Length()) == ','){    query = query.subString(0,query.Length()-1);}
        
        query += ' FROM ' + objectName;
        query += ' WHERE Id IN :setContractIds'; 
        
        try {        
            result = database.query(query);
            
        } catch (QueryException e){ 
            //do nothing
            System.debug('@@@@@88888 error' +e.getMessage());
        }
        
        return result;
    }
    
    //------------------------------------
    public static Contract GetContractWithAllFeilds(string contractId) {
        String objectName = 'Contract';
        String query = 'SELECT';
        Contract result = null;
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
    
        for(String s : objectFields.keySet()) {   query += ' ' + s + ',';}
        
        // Strip off the last comma if it exists.
        if (query.subString(query.Length()-1,query.Length()) == ','){    query = query.subString(0,query.Length()-1);}
        
        query += ' FROM ' + objectName;
        query += ' WHERE Id = \'' + contractId + '\'';
        
        try {        
            result = database.query(query);
        } catch (QueryException e){ 
            //do nothing
            System.debug('@@@@@####### error' +e.getMessage());
        }
        
        return result;
    }
}