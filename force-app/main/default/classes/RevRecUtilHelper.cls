public class RevRecUtilHelper {
    
    //Map is used to hold the field permission
    Static Map<String, Schema.DescribeFieldResult> mapfieldRevRecJobResult = Utility.getFieldPermissions('RevRecJob__c');
    
    /** 
     *  @description    :   This method is used to calculate start and end date for am rule.
    **/                                 
    public AmortizeMileStartEndDate startEndDateForAMRule (Date startDate, Date endDate, Opportunity oppty, OpportunityLineItem lineItem , Product2 pro
                , String RevRecEndDateField , String RevRecStartDateField, Contract contr) {

        //Wraper 
        AmortizeMileStartEndDate wrap = new AmortizeMileStartEndDate(startDate,endDate);
        
        //Calculating end date
         if (RevRecEndDateField != null && RevRecEndDateField.contains(constants.SOBJECT_OPPORTUNITY)){
            if(RevRecEndDateField.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
                string fieldName = RevRecEndDateField.subString(20, RevRecEndDateField.length());
                endDate = (Date)lineItem.get(fieldName);    
            }
            else {
                string fieldName = RevRecEndDateField.subString(12, RevRecEndDateField.length());
                endDate = (Date)oppty.get(fieldName);
            }    
         } else if (RevRecEndDateField != null && RevRecEndDateField.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
            string fieldName = RevRecEndDateField.subString(8, RevRecEndDateField.length());
            endDate = (Date)pro.get(fieldName);
         } else if (RevRecEndDateField != null && RevRecEndDateField.contains(constants.SOBJECT_CONTRACT_COLON)) {
            string fieldName = RevRecEndDateField.subString(9, RevRecEndDateField.length());
            endDate = (Date)contr.get(fieldName);
         } 
         
         //Calculating start date
         if (RevRecStartDateField != null && RevRecStartDateField.contains(constants.SOBJECT_OPPORTUNITY)){
            if(RevRecStartDateField.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
                string fieldName = RevRecStartDateField.subString(20, RevRecStartDateField.length()); 
                startDate = (Date)lineItem.get(fieldName);
            }
            else {
                string fieldName = RevRecStartDateField.subString(12, RevRecStartDateField.length()); 
                startDate = (Date)oppty.get(fieldName);
            }
         } else if (RevRecStartDateField != null && RevRecStartDateField.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
            string fieldName = RevRecStartDateField.subString(8, RevRecStartDateField.length());
            startDate = (Date)pro.get(fieldName);
         } else if (RevRecStartDateField != null && RevRecStartDateField.contains(constants.SOBJECT_CONTRACT_COLON)) {
            string fieldName = RevRecStartDateField.subString(9, RevRecStartDateField.length());
            startDate = (Date)contr.get(fieldName);
         }
         
         wrap.startDate = startDate;
         wrap.endDate = endDate;
         
         return wrap;
    }
    
    public string CalculateTotalPeriodForWeeklyAmortized(Date startDate, Date endDate, RevRecProductRule__c overrideRule){
        
        string result = '';
        Integer totalDays = startDate.daysBetween(endDate) + 1;
        Integer totalWeeks = (totalDays - 1)/7 + 1;
        overrideRule.Total_Period__c = null;

        return result;                  
    } 
    
    public string ExecuteOpportunityJob(String oppId, String desp, Date shedulerDate){
        integer status = 0;
        string msg = '';
        RevRecUtil util = new RevRecUtil();
        system.debug(oppId + ': ' + desp + ' at ' + shedulerDate);
        try {
            msg = util.EvaluateRevRecScheduleForOpportunity(oppId);
            if (msg.length() == 0) status = 1;
        } catch (exception exp) {
            System.Debug(exp);
            msg = exp.getLineNumber() + 'Exception:' + exp.getMessage();
        } finally {
            RevRecJob__c theJobRecord = null;
            List<RevRecJob__c> jobRecordList = [SELECT Id, Name, OpportunityID__c, status__c, status_date__c, description__c FROM RevRecJob__c WHERE OpportunityID__c = :oppId ];
            
            if (jobRecordList.size() == 0 ) {
                theJobRecord = new RevRecJob__c(OpportunityID__c = oppId, status_date__c = shedulerDate, description__c = desp, status__c = status);
                insert(theJobRecord);
                msg += ' inserted';
            } else {
                theJobRecord = jobRecordList[0];  
                if(Utility.checkFieldPermission(mapfieldRevRecJobResult,'status_date__c',Constants.PERMISSION_UPDATE))
                    theJobRecord.status_date__c = shedulerDate;
                if(Utility.checkFieldPermission(mapfieldRevRecJobResult,'status__c',Constants.PERMISSION_UPDATE))
                    theJobRecord.status__c = status;
                if(Utility.checkFieldPermission(mapfieldRevRecJobResult,'description__c',Constants.PERMISSION_UPDATE))
                    theJobRecord.description__c = desp;
                if(Utility.checkObjectPermission(Constants.PERMISSION_UPDATE, 'RevRecJob__c')){
                    update(theJobRecord);
                }
                msg += ' updated';          
            }
        }
        return msg;
    }
    
    /** 
     *  This method is used to get the start and end percentage counter
    **/
    public static String getStartEndPercentageCount (RevRecProductRule__c rule) {
        
        String msg = '';
        //Checking for override rule divide by option
        if(rule.Divide_By__c == 'Prorate') {
                        
             if(rule.Start_Percentage__c == null)
                rule.Start_Percentage__c = 0.00;
            
            if(rule.End_Percentage__c == null)
                rule.End_Percentage__c = 0.00;
            
            //Code is added on 05/05/2017 for urgent fixes on Amortize and Amortized Milestone
            //Check for rule start and end % total not exeed 100
            if(rule.Start_Percentage__c != null || rule.End_Percentage__c != null) {
                
                Decimal totalPercentage = rule.Start_Percentage__c + rule.End_Percentage__c;
                
                if(totalPercentage != 100.00)
                    msg =  Constants.RULE_START_AND_END_PERCENTAGE_NOT_MORE_THAN_100;
            }
        }
        return msg;
    }
    
    /**
     *  @description    :   This method is used to create/update the error log records.
     *
     *  @return         :   -
     *
     *  @args           :   Id OpportunityID ,  Exception e
     **/
    public void createErrorLog (Id OpportunityID, Exception e) {  
        
        //Instance of Error log
        List<RevView_Error_Log__c> errLogs = new List<RevView_Error_Log__c>();
        
        //Query to fetch the Error log record  related to opportunity
        List<RevView_Error_Log__c>  errorLogs = [Select Id, Name, Error_Log_Message__c ,Stack_Trace__c,Type_Of_Exception__c,
             Line_Number__c From RevView_Error_Log__c 
             Where Opportunity__c =: OpportunityID LIMIT 1];
        
        //Checking for the existing error log record
        if(errorLogs.size() > 0) 
            
            errLogs.add(new RevView_Error_Log__c(Id = errorLogs[0].Id , Error_Log_Message__c = e.getMessage(), Stack_Trace__c = e.getStackTraceString().left(255),
                                    Type_Of_Exception__c = e.getTypeName(), Line_Number__c = e.getLineNumber()));
        else 
            errLogs.add(new RevView_Error_Log__c(Error_Log_Message__c = e.getMessage(), Stack_Trace__c = e.getStackTraceString().left(255),
                                    Type_Of_Exception__c = e.getTypeName(), Line_Number__c = e.getLineNumber(), Opportunity__c = OpportunityID ));
        
        //Upsert 
        upsert errLogs;
    } 
    
    //Method to check whether multi currency setting was enabled for the org or not
    public static Boolean checkMCEnabled(){
        
        Boolean isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
        Schema.SObjectType mcEnabled;
        
        if(isMultiCurrencyEnabled) {
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            mcEnabled = gd.get('DatedConversionRate');
        }
        return (mcEnabled != null) ? true : false;
    } 
    
    public static Integer GetFiscalMonth(Date theDate, RevRecAppSetting__c theSetting) {
        
        Integer theMonth = theDate.month();
        
        if (theSetting.Time_of_Month_Selection_Types__c == '1') { //last day of the month
            //do nother
        } else if (theSetting.Time_of_Month_Selection_Types__c == '2') { // Date of the month
        
            Integer settingDateInTheMonth = Integer.valueOf(theSetting.Certain_date_of_month__c);
        
            if (theDate.day() > settingDateInTheMonth) 
                theMonth = theDate.addMonths(1).month();
        } else if (theSetting.Time_of_Month_Selection_Types__c == '3') { //certain weekday of certain week
        
            Date certainWeekCertainWeekdayForTheDate = RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(theDate, theSetting.Certain_weekday__c, theSetting.Certain_weekday_day__c);
        
            if (theDate > certainWeekCertainWeekdayForTheDate)
                theMonth = theDate.addMonths(1).month();
        } 
        return theMonth;
    } 
    
    /** 
     *  @description        :   This method is used to delete the existing revrecopportunitylineitem record.
     **/
    public void Cleanup() {
        
        try {
            
            List<RevRecOpportunityLineItem__c> garbage = [select id, name from RevRecOpportunityLineItem__c where id not in (select RevRecOpportunityLineItem__c from OpportunityLineItem)];
            if (RevRecOpportunityLineItem__c.sObjectType.getDescribe().isDeletable()) {
                delete(garbage);
            }
        } catch (Exception exp){
            System.debug('@@@ Error @@@ 222' +exp);
        }
    }
    
    /** 
     *  @description        :   This method is used to delete the schedules.
     **/
     public void scheduleCleanup(Set<Id> lineItemIds) {
       
       try {
           List<RevRecOpportunityLineItemSchedule__c> garbage = [SELECT Id, Name FROM RevRecOpportunityLineItemSchedule__c 
                                                                 WHERE OpportunityLineItemId__c != null AND OpportunityLineItemId__c != ''
                                                                 AND AppRopozSLN__External_OpportunityLineItemId__c in : lineItemIds];
           if (RevRecOpportunityLineItemSchedule__c.sObjectType.getDescribe().isDeletable()) {
               delete(garbage);
           }
           
       } catch (Exception exp){
           exp.getMessage(); 
       }
    }
    /** 
    *  @description        :   This method is used to calculate the year difference between start and end date.
    **/
    public Integer yearDifference(Date dt1 , Date dt2) {
        
        //Difference
        if(dt1 != null && dt2 != null) {
            Integer difference = dt2.year() - dt1.year();
            return difference;
        }
        return 0;
    }
    /** 
    *  @description        :   This method is used to calculate the month difference between start and end date.
    **/
    public Integer monthDifference(Date dt1 , Date dt2) {
        
        //Difference
        if(dt1 != null && dt2 != null) {
            Integer difference = dt1.monthsBetween(dt2);
                if (dt2.day() > dt1.day()) difference++;
                    return difference;
        }
        return 0;
    }
    
    /** This method is used to calculate recognition for amortize milstone rule **/
    public List<Decimal> getRecognigibleFORAM (Date startDate , Date endDate , RevRecProductRule__c overridenRule , Decimal recognigibleAMT , Integer totalMonths,
                                                List<Decimal>  recognizableForEachMonths , Decimal initialAmt) {
        
        if(initialAmt == null)
            initialAmt = 0;
        
        Date tempStartDate = startDate;  
        Decimal firstMonthRecognizableByDailyRatio = 0.00;
        Decimal lastMonthRecognizableByDailyRatio = 0.00;
        Integer totalDays = startDate.daysBetween(endDate) + 1;
        
        Decimal dailyRecognizable;
        
        if(totalDays > 0)
        	dailyRecognizable = (recognigibleAMT/totalDays).setScale(2);
        else
        	dailyRecognizable = 0.0;
        
        Date newStartDate;
        Date newStartDateTemp;
                
        //if 0
        if(totalMonths == 0)
            totalMonths = 1;
        
        Decimal monthlyRecognizable = ((recognigibleAMT)/totalMonths);
        
        if(totalMonths > 0) {                              
            if(overridenRule != null &&  overridenRule.Divide_By__c  == 'Period') {
                
                if (overridenRule.Period_or_Exact_Days__c == 'period') {                                            
                    for (Integer j=0; j < totalMonths; j++) {                      
                        
                        if(j == 0) 
                            recognizableForEachMonths.add((monthlyRecognizable + initialAmt).setScale(2));
                        else 
                            recognizableForEachMonths.add((monthlyRecognizable).setScale(2));
                    }
                } else if (overridenRule.Period_or_Exact_Days__c == 'exact') {
                    Integer totalDaysInPeriod = 0;
                    
                    for (Integer j=0; j < totalMonths; j++) {                
                                        
                        //FOR End schedule
                        if(j == (totalMonths -1)) {
                            
                            //chekin for null
                            if(newStartDateTemp == null)
                                newStartDateTemp = startDate;
                                
                            //Total days in last period
                            totalDaysInPeriod = newStartDateTemp.daysBetween(endDate);
                        }
                        else {
                            
                            //checking for null
                            if(newStartDate == null)
                                newStartDate = startDate;
                            
                            //Calculating total periods 
                            totalDaysInPeriod = newStartDate.daysBetween(newStartDate.addMonths(1));
                            
                            //Start dates
                            newStartDate = newStartDate.addMonths(1);
                            newStartDateTemp = startDate.addMonths(j+1);
                        }                   
                                                                           
                        //Recognized amount
                        if(j == 0)
                            recognizableForEachMonths.add( getPeriodAmount(totalDaysInPeriod,(dailyRecognizable  +initialAmt)));
                        else
                            recognizableForEachMonths.add( getPeriodAmount(totalDaysInPeriod,dailyRecognizable));
                            
                    }
                }
            } else if(overridenRule.Divide_By__c != null &&  overridenRule.Divide_By__c  == 'nonProrate') { //2nd option
               
                firstMonthRecognizableByDailyRatio = (dailyRecognizable * startDate.daysBetween(startDate.addMonths(1).toStartOfMonth())).setScale(2);
                lastMonthRecognizableByDailyRatio = (dailyRecognizable * endDate.day()).setScale(2);
                
                if (overridenRule.Period_or_Exact_Days__c == 'period') {
                
                    Decimal actualAmountForAllMonth = 0.00;
                                        
                    if(totalMonths > 2)
                        actualAmountForAllMonth = ((recognigibleAMT-firstMonthRecognizableByDailyRatio-lastMonthRecognizableByDailyRatio)/(totalMonths - 2)).setScale(2);
                    else
                        actualAmountForAllMonth = (recognigibleAMT-firstMonthRecognizableByDailyRatio-lastMonthRecognizableByDailyRatio);
                    for (Integer j=0; j < totalMonths; j++) {  
                        
                        if(j==0)
                            recognizableForEachMonths.add(firstMonthRecognizableByDailyRatio + initialAmt);
                        else if(j == (totalMonths-1))
                            recognizableForEachMonths.add(lastMonthRecognizableByDailyRatio);
                        else
                            recognizableForEachMonths.add(actualAmountForAllMonth);
                    }
                } else if (overridenRule.Period_or_Exact_Days__c == 'exact') {
                    
                    totalDays = 0;
                    
                    for (Integer j=1; j < totalMonths-1; j++) { 
                        
                        tempStartDate = tempStartDate.addMonths(j);
                        totalDays += Date.daysInMonth(tempStartDate.year(), tempStartDate.month());
                    }
                    
                    tempStartDate = startDate;
                    
                    for (Integer j=0; j < totalMonths; j++) {
                        
                        if(j==0)
                            recognizableForEachMonths.add(firstMonthRecognizableByDailyRatio + initialAmt);
                        else if(j == (totalMonths-1))
                            recognizableForEachMonths.add(lastMonthRecognizableByDailyRatio);
                        else
                            recognizableForEachMonths.add((dailyRecognizable * Date.daysInMonth(tempStartDate.year(), tempStartDate.month())).setScale(2));
                            
                        tempStartDate = tempStartDate.addMonths(1);
                    }
                } 
            } else if(overridenRule.Divide_By__c != null &&  overridenRule.Divide_By__c  == 'Prorate') { //3rd option
                
                Decimal monthlyRecognizableAmount = 0.00;
                
                if(totalMonths > 1)
                    monthlyRecognizableAmount = ((recognigibleAMT)/(totalMonths-1));
                else
                    monthlyRecognizableAmount = (recognigibleAMT);
                                                            
                if(overridenRule.Start_Percentage__c != null) 
                    firstMonthRecognizableByDailyRatio = (monthlyRecognizableAmount * (overridenRule.Start_Percentage__c /100)).setScale(2);
                
                if(overridenRule.End_Percentage__c != null)
                    lastMonthRecognizableByDailyRatio = (monthlyRecognizableAmount * (overridenRule.End_Percentage__c /100)).setScale(2); 
                
                if (overridenRule.Period_or_Exact_Days__c == 'period') {
                    
                    for (Integer j=0; j < totalMonths; j++) {  
                    
                        if(j==0)
                            recognizableForEachMonths.add(firstMonthRecognizableByDailyRatio + initialAmt);
                        else if(j == (totalMonths-1))
                            recognizableForEachMonths.add(lastMonthRecognizableByDailyRatio);
                        else
                            recognizableForEachMonths.add(monthlyRecognizableAmount);
                    }
                    
                } else if (overridenRule.Period_or_Exact_Days__c == 'exact') {
                    
                    totalDays = 0;
                    
                    for (Integer j=1; j < totalMonths-1; j++) { 
                        
                        tempStartDate = tempStartDate.addMonths(j);
                        totalDays += Date.daysInMonth(tempStartDate.year(), tempStartDate.month());
                    }
                    
                    dailyRecognizable = ((recognigibleAMT-(firstMonthRecognizableByDailyRatio + lastMonthRecognizableByDailyRatio))/(totalDays-1)).setScale(2);
                    tempStartDate = startDate;
                    
                    for (Integer j=0; j < totalMonths; j++) {  
                    
                        if(j==0)
                            recognizableForEachMonths.add(firstMonthRecognizableByDailyRatio + initialAmt);
                        else if(j == (totalMonths-1))
                            recognizableForEachMonths.add(lastMonthRecognizableByDailyRatio);
                        else 
                            recognizableForEachMonths.add((dailyRecognizable * Date.daysInMonth(tempStartDate.year(), tempStartDate.month())).setScale(2));
                        tempStartDate = tempStartDate.addMonths(1);
                    }
                }
            }
        }
        
        //Loop over recognizableForEachMonths
        if(recognizableForEachMonths.size() > 0) {
            
            Decimal sumOfAmt = 0.00;
            
            //Looping
            for(Decimal recAmt : recognizableForEachMonths) 
                sumOfAmt += recAmt;
            
            if(sumOfAmt != (recognigibleAMT + initialAmt))   {
                
                if(overridenRule.Divide_By__c  != 'Prorate')
                    recognizableForEachMonths[totalMonths-1] += (recognigibleAMT+initialAmt - sumOfAmt);
                else {
                    
                    if(totalMonths >= 2)
                        recognizableForEachMonths[totalMonths-2] += (recognigibleAMT+initialAmt - sumOfAmt);
                }
            }                                   
        }
                                                    
        //In case if start and end date in same month
        if(startDate.year() == endDate.year()) {
        
            if(startDate.month() == endDate.month()) {
                
                recognizableForEachMonths = new List<Decimal>();
                recognizableForEachMonths.add(recognigibleAMT + initialAmt);
            }
            
            if(totalMonths == 1) {
                
                recognizableForEachMonths = new List<Decimal>();
                recognizableForEachMonths.add(recognigibleAMT + initialAmt);
            }            
        } 
        return recognizableForEachMonths;
    }
    
    public static Decimal getPeriodAmount (Integer totalDays , Decimal perDayAmt) {
        
        Decimal periodAmt = totalDays * perDayAmt;
        return periodAmt; 
    }
    
    public Integer getTotalMonths(Date startDate, Date endDate, Integer totalMonths ,RevRecProductRule__c overridenRule) {       
        
        if(startDate.year() == endDate.year()) {
                
            if(startDate.Month() == endDate.month() ) {
                totalMonths = totalMonths;
            }else {
                if(StartDate.day() <= endDate.day()) 
                    totalMonths = totalMonths +1;                   
            }
        }else {
            if(StartDate.day() <= endDate.day()) 
                totalMonths = totalMonths +1;           
        }
        
        if((overridenRule.Divide_By__c  == 'Prorate' || overridenRule.Divide_By__c  == 'nonProrate')  && StartDate.day() > endDate.day())
            totalMonths = totalMonths +1;  

         return totalMonths; 
    }
    
    public string DailyAmortized(RevRecProductRule__c overrideRule, Integer sequence, Double recognizableTotal, double initial, Date startDate, Date endDate,
                                            Opportunity oppty, OpportunityLineItem lineItem, RevRecOpportunityLineItem__c revrecLineItem,
                                            List<RevRecOpportunityLineItemSchedule__c> revenuSchedules){
        String result = '';
        Double recognizedTotal = 0;
        Boolean isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
                                                
        if(endDate!= null) {
            
            if (startDate > endDate) return 'End date is before start date';
            
            Integer totalDays = startDate.daysBetween(endDate) + 1;
            double dailyRecognizable= (recognizableTotal-initial)/totalDays;
            Date initialDate = startDate;
            Date now = Date.today();
            double periodAccumulated = 0;
            
            for (Integer i=0; i < totalDays; i++) {
            
                RevRecOpportunityLineItemSchedule__c theSchedule = new RevRecOpportunityLineItemSchedule__c();
                theSchedule.OpportunityLineItemId__c = lineItem.Id;
                
                //Code modified - (1/8/2015) - Check if multi currency enabled then do this
                if(isMultiCurrencyEnabled)
                    theSchedule.put('CurrencyIsoCode', oppty.get('CurrencyIsoCode'));
                
                theSchedule.OriginalDate__c = initialDate.addDays(i);
                theSchedule.Date__c = initialDate.addDays(i);
                theSchedule.Month__c = theSchedule.Date__c.month() +'' ;
                
                if (i== 0) 
                    theSchedule.RecognizedRev__c = dailyRecognizable + initial;
                else if (i == totalDays -1 )
                    theSchedule.RecognizedRev__c = recognizableTotal - periodAccumulated;
                else 
                    theSchedule.RecognizedRev__c = dailyRecognizable;
                
                periodAccumulated += theSchedule.RecognizedRev__c;
                theSchedule.DeferredRev__c = recognizableTotal - periodAccumulated;
                             
                if (theSchedule.Date__c <= now) 
                    recognizedTotal +=  theSchedule.RecognizedRev__c;
                
                theSchedule.RevRecOpportunityLineItem__c = lineItem.RevRecOpportunityLineItem__c;
                theSchedule.Sequence__c =  i + 1;      
                theSchedule.RecognizedRevTotal__c = periodAccumulated;
                theSchedule.Rec_Total_Amt_Wei__c = (periodAccumulated * oppty.Probability) / 100;
                theSchedule.ResidualAmountTotal__c = revreclineItem.ResidualAmount__c;
                theSchedule.LineItemAmountTotal__c = lineItem.TotalPrice; 
                theSchedule.LI_Amt_Total_Wei__c = (lineItem.TotalPrice * oppty.Probability) / 100;
                theSchedule.RecRevWei__c = (theSchedule.RecognizedRev__c * oppty.Probability) / 100;
                theSchedule.DefReWei__c = (theSchedule.DeferredRev__c * oppty.Probability) / 100;
                
                if(lineItem.TotalPrice == 0)
                    theSchedule.Recognized_Quantity__c = 0;
                else    
                    theSchedule.Recognized_Quantity__c = (((theSchedule.RecognizedRev__c * 100)/lineItem.TotalPrice) * lineItem.Quantity)/100; 
                
                revenuSchedules.add(theSchedule);                                   
            }
    
            revreclineItem.RecognizedRev__c = recognizedTotal;
            revreclineItem.DeferredRev__c = recognizableTotal - revreclineItem.RecognizedRev__c;
            revreclineItem.RecRevWei__c = (recognizedTotal * oppty.Probability)/100;
            revreclineItem.DeferredRev__c = (revreclineItem.DeferredRev__c * oppty.Probability)/100;
            revreclineItem.CalculatedAt__c = date.today();
            revreclineItem.TotalRev__c = recognizableTotal;
            revreclineItem.Total_Amt_Wei__c = (recognizableTotal * oppty.Probability)/100;
        }
        return result;                  
    }
    
    public string CalculateTotalPeriodForYearlyAmortized(Date startDate, Date endDate, RevRecProductRule__c overrideRule, RevRecAppSetting__c theSetting){
        string result = '';
        Integer totalMonth = startDate.monthsBetween(endDate);
        if (startDate.day() <= endDate.day()) totalMonth++;
        Boolean startInCurrentMonth = true;
        if (theSetting.Time_of_Month_Selection_Types__c == '1') { //last day of the month
                    // do nothing
        } else if (theSetting.Time_of_Month_Selection_Types__c == '2') { // Date of the month
            Integer settingDateInTheMonth = Integer.valueOf(theSetting.Certain_date_of_month__c);
            if (startDate.day() > settingDateInTheMonth) {
                totalMonth--; 
                startInCurrentMonth = false;
            }
            if (endDate.day() >  settingDateInTheMonth)
                totalMonth++;               
        } else if (theSetting.Time_of_Month_Selection_Types__c == '3') { //certain weekday of certain week
            Date certainWeekCertainWeekdayForStartDate = RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(startDate, theSetting.Certain_weekday__c, theSetting.Certain_weekday_day__c);
            if (startDate > certainWeekCertainWeekdayForStartDate) {
                totalMonth--; 
                startInCurrentMonth = false;
            }
            Date certainWeekCertainWeekdayForEndDate = RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(endDate, theSetting.Certain_weekday__c, theSetting.Certain_weekday_day__c);
            if (endDate >  certainWeekCertainWeekdayForEndDate) 
                totalMonth++;
        } 
        
        Integer totalYears = (totalMonth -1)/12 + 1;
        overrideRule.Total_Period__c = null;
        
        return result;                  
    }
    
    public string CalculateTotalPeriodForQuartlyAmortized(Date startDate, Date endDate, RevRecProductRule__c overrideRule, RevRecAppSetting__c theSetting){
        string result = '';

        Integer totalMonth = startDate.monthsBetween(endDate); 
        if (startDate.day() <= endDate.day()) totalMonth++;
        Integer totalDays = startDate.daysBetween(endDate) + 1;
        Boolean startInCurrentMonth = true;
        if (theSetting.Time_of_Month_Selection_Types__c == '1') { //last day of the month
                    // do nothing
        } else if (theSetting.Time_of_Month_Selection_Types__c == '2') { // Date of the month
            Integer settingDateInTheMonth = Integer.valueOf(theSetting.Certain_date_of_month__c);
            if (startDate.day() > settingDateInTheMonth) {
                totalMonth--; 
                startInCurrentMonth = false;
            }
            if (endDate.day() >  settingDateInTheMonth) {
                totalMonth++;               
            }
        } else if (theSetting.Time_of_Month_Selection_Types__c == '3') { //certain weekday of certain week
            Date certainWeekCertainWeekdayForStartDate = RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(startDate, theSetting.Certain_weekday__c, theSetting.Certain_weekday_day__c);
            if (startDate > certainWeekCertainWeekdayForStartDate) {
                totalMonth--; 
                startInCurrentMonth = false;
            }
            Date certainWeekCertainWeekdayForEndDate = RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(endDate, theSetting.Certain_weekday__c, theSetting.Certain_weekday_day__c);
            if (endDate >  certainWeekCertainWeekdayForEndDate) 
                totalMonth++;               
        } 
        
        integer totalPeriod = (totalMonth - 1) / 3 + 1;
        
        Date initialDate = startDate;
        overrideRule.Total_Period__c = null;
        return result;                  
    }
    
   public string MonthlyAmortized(RevRecProductRule__c overrideRule, Integer sequence, Double recognizableTotal, double initial, String DevidedByType,
                                  Date startDate, Date endDate, String DevidedBy,
                                  Opportunity oppty, OpportunityLineItem lineItem, RevRecOpportunityLineItem__c revReclineItem,
                                  List<RevRecOpportunityLineItemSchedule__c> revenuSchedules, RevRecAppSetting__c theSetting) {
         
        List<Decimal> recognizableForEachMonths = new List<Decimal>();
        String result = '';
        Decimal recognizableTotalForExact = recognizableTotal - initial;      
        Integer totalPeriod = 0;
        Decimal periodAmount = 0.00;
        Decimal periodAmountProrate = 0.00;
        Date initialDate = startDate;
        Date now = Date.today();
        Decimal monthlyAccumulated = 0.00;
        Decimal recognizedTotal = 0.00;
        Integer totalDays = 0;
        Decimal amountPerDay = 0.00;
        Boolean startInCurrentMonth = true;
        Integer remainingDays = 0;
        List<RevRecOpportunityLineItemSchedule__c> revenuSchedulesCopy = new List<RevRecOpportunityLineItemSchedule__c>();
        Boolean isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
        //Code modified for same month issue when schedule is not creating - 25/05/2018       //------------------

        if(startDate.year() == endDate.year() && startDate.month() == endDate.month())
        	totalPeriod = 1;
    	else
        	totalPeriod =  startDate.monthsBetween(endDate);
        totalPeriod = getTotalMonths(startDate, endDate, totalPeriod, overrideRule);
        
        recognizableForEachMonths = getRecognigibleFORAM(startDate, endDate, overrideRule, (recognizableTotal-initial), 
                                                          totalPeriod, recognizableForEachMonths, initial);
	
        //Temp var
        Date newStartDate ;
        Date newStartDateTemp;
        Decimal totalAMForAllMonths = 0.00;
            
        for (Integer i=0; i < totalPeriod; i++) {
                
            //assign the common value
            RevRecOpportunityLineItemSchedule__c theSchedule = new RevRecOpportunityLineItemSchedule__c();
            theSchedule.OpportunityLineItemId__c = lineItem.Id;
            
            //Code modified - (1/8/2015) - Check if multi currency enabled then do this
            if(isMultiCurrencyEnabled)
                theSchedule.put('CurrencyIsoCode', oppty.get('CurrencyIsoCode'));
            
            theSchedule.RevRecOpportunityLineItem__c = lineItem.RevRecOpportunityLineItem__c;
            
            if(initialDate != null) {
                theSchedule.OriginalDate__c = initialDate.addMonths(i);
                theSchedule.Date__c = GetTransDate(initialDate.addMonths(i), startInCurrentMonth, theSetting);
                theSchedule.Month__c = theSchedule.Date__c.month() +'' ;
            }
            if(!Test.isRunningTest())
                theSchedule.RecognizedRev__c = recognizableForEachMonths[i];
            
            //In case if start and end date in same month
            if(startDate.year() == endDate.year()) {
            
                if(startDate.month() == endDate.month()) 
                    theSchedule.RecognizedRev__c = recognizableTotal ;
                
                if(totalPeriod == 1)
                    theSchedule.RecognizedRev__c = recognizableTotal ;
            }
            
            if(theSchedule.RecognizedRev__c == null)
                theSchedule.RecognizedRev__c = 0.00;
                
            monthlyAccumulated += theSchedule.RecognizedRev__c;
            theSchedule.DeferredRev__c = recognizableTotal - monthlyAccumulated;
                         
            if (theSchedule.Date__c <= now) 
                recognizedTotal +=  theSchedule.RecognizedRev__c;
            theSchedule.Sequence__c = i + 1 ;
            
            //Holding whole amount
            totalAMForAllMonths  +=  theSchedule.RecognizedRev__c.setScale(2);
             
            theSchedule.RecognizedRevTotal__c = monthlyAccumulated;
            theSchedule.Rec_Total_Amt_Wei__c = (monthlyAccumulated * oppty.Probability) / 100;
            theSchedule.ResidualAmountTotal__c = revreclineItem.ResidualAmount__c;
            theSchedule.LineItemAmountTotal__c = lineItem.TotalPrice; 
            theSchedule.LI_Amt_Total_Wei__c = (lineItem.TotalPrice * oppty.Probability) / 100;
            
            if(lineItem.TotalPrice == 0) 
                theSchedule.Recognized_Quantity__c = 0;
            else
                theSchedule.Recognized_Quantity__c = (((theSchedule.RecognizedRev__c * 100)/lineItem.TotalPrice) * lineItem.Quantity)/100;     
             
            theSchedule.RecRevWei__c = (theSchedule.RecognizedRev__c * oppty.Probability)/100;
            theSchedule.DefReWei__c = (theSchedule.DeferredRev__c * oppty.Probability)/100;
                                      
            revenuSchedulesCopy.add(theSchedule);        
        }
		
        if(totalAMForAllMonths != (recognizableTotal - initial)) {
            
            Decimal amountDiff  = totalAMForAllMonths - (recognizableTotal );
            if(revenuSchedulesCopy.size() > 0 && totalPeriod >=1) {

                if(DevidedBy != 'Prorate') {

                    revenuSchedulesCopy[totalPeriod -1].RecognizedRev__c -= amountDiff;
                    revenuSchedulesCopy[totalPeriod -1].DeferredRev__c += amountDiff;
                    //Added on 03/05/2018 for Issue #7
                    revenuSchedulesCopy[totalPeriod -1].RecRevWei__c = (revenuSchedulesCopy[totalPeriod -1].RecognizedRev__c * oppty.Probability)/100;
                    //revenuSchedulesCopy[totalPeriod -1].RecRevWei__c -= revenuSchedulesCopy[totalPeriod -1].RecognizedRev__c * oppty.Probability;
                    //revenuSchedulesCopy[totalPeriod -1].DefReWei__c += revenuSchedulesCopy[totalPeriod -1].DeferredRev__c * oppty.Probability;
                    revenuSchedulesCopy[totalPeriod -1].DefReWei__c = (revenuSchedulesCopy[totalPeriod -1].DeferredRev__c * oppty.Probability)/100;
                    if(recognizedTotal >= amountDiff)
                        recognizedTotal -= amountDiff;
                }else {
                    
                    if(totalPeriod >=2) {
                        revenuSchedulesCopy[totalPeriod -2].RecognizedRev__c -= amountDiff;
                        revenuSchedulesCopy[totalPeriod -2].DeferredRev__c += amountDiff;
                        revenuSchedulesCopy[totalPeriod -1].DeferredRev__c += amountDiff;
                    	//Added on 03/05/2018 for Issue #7
                        revenuSchedulesCopy[totalPeriod -2].RecRevWei__c = (revenuSchedulesCopy[totalPeriod -2].RecognizedRev__c * oppty.Probability)/100;
                        //revenuSchedulesCopy[totalPeriod -2].RecRevWei__c -= revenuSchedulesCopy[totalPeriod -2].RecognizedRev__c * oppty.Probability;
                        //revenuSchedulesCopy[totalPeriod -1].DefReWei__c += revenuSchedulesCopy[totalPeriod -1].DeferredRev__c * oppty.Probability;
                        //revenuSchedulesCopy[totalPeriod -2].DefReWei__c += revenuSchedulesCopy[totalPeriod -2].DeferredRev__c * oppty.Probability;
                        revenuSchedulesCopy[totalPeriod -1].DefReWei__c = (revenuSchedulesCopy[totalPeriod -1].DeferredRev__c * oppty.Probability)/100;
                        revenuSchedulesCopy[totalPeriod -2].DefReWei__c = (revenuSchedulesCopy[totalPeriod -2].DeferredRev__c * oppty.Probability)/100;
                    }
                }
            }
        }
        
        revreclineItem.RecognizedRev__c = recognizedTotal;
        revreclineItem.DeferredRev__c = recognizableTotal - revreclineItem.RecognizedRev__c;
        revreclineItem.RecRevWei__c = (recognizedTotal * oppty.Probability) / 100;
        revreclineItem.DefReWei__c = (revreclineItem.RecognizedRev__c * oppty.Probability) / 100;
        revreclineItem.CalculatedAt__c = date.today();
        revreclineItem.TotalRev__c = recognizableTotal; 
        revreclineItem.Total_Amt_Wei__c = (recognizableTotal * oppty.Probability)/100;
        revenuSchedules.addAll(revenuSchedulesCopy);

       return result;     
    }
    
    public string WeeklyAmortized(RevRecProductRule__c overrideRule, Integer sequence, Double recognizableTotal, double initial,
                                            Date startDate, Date endDate, 
                                            Opportunity oppty, OpportunityLineItem lineItem, RevRecOpportunityLineItem__c revreclineItem,
                                            List<RevRecOpportunityLineItemSchedule__c> revenuSchedules, RevRecAppSetting__c theSetting){
        string result = '';
        Double recognizedTotal = 0;
        Boolean isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
                                                
        if (endDate != null) {
            Integer totalDays = startDate.daysBetween(endDate) + 1;
            Integer totalWeeks = (totalDays - 1)/7 + 1;
            
            double weeklyRecognizable= (recognizableTotal-initial)/totalWeeks;
            
            Date initialDate = startDate;
            Date now = Date.today();
            double weeklyAccumulated = 0;
            for (Integer i=0; i < totalWeeks; i++) {
                RevRecOpportunityLineItemSchedule__c theSchedule = new RevRecOpportunityLineItemSchedule__c();
                theSchedule.OpportunityLineItemId__c = lineItem.Id;
                
                  //Code modified - (1/8/2015) - Check if multi currency enabled then do this
                  if(isMultiCurrencyEnabled)
                        theSchedule.put('CurrencyIsoCode', oppty.get('CurrencyIsoCode'));
                
                theSchedule.Date__c = initialDate.addDays(i * 7);
                theSchedule.OriginalDate__c = initialDate.addDays(i * 7);
                theSchedule.Month__c = GetFiscalMonth(theSchedule.Date__c, theSetting) + '' ;
                
                if (i== 0) 
                    theSchedule.RecognizedRev__c = weeklyRecognizable + initial;
                else if (i == totalWeeks -1 )
                    theSchedule.RecognizedRev__c = recognizableTotal - weeklyAccumulated;
                else 
                    theSchedule.RecognizedRev__c = weeklyRecognizable;
                
                weeklyAccumulated += theSchedule.RecognizedRev__c;
                theSchedule.DeferredRev__c = recognizableTotal - weeklyAccumulated;
                             
                if (theSchedule.Date__c <= now) 
                    recognizedTotal +=  theSchedule.RecognizedRev__c;
                
                theSchedule.RevRecOpportunityLineItem__c = lineItem.RevRecOpportunityLineItem__c;
                theSchedule.Sequence__c = i + 1 ;    
    
                theSchedule.RecognizedRevTotal__c = weeklyAccumulated;
                theSchedule.Rec_Total_Amt_Wei__c = (weeklyAccumulated * oppty.Probability) / 100;
                theSchedule.ResidualAmountTotal__c = revreclineItem.ResidualAmount__c;
                theSchedule.LineItemAmountTotal__c = lineItem.TotalPrice;
                theSchedule.LI_Amt_Total_Wei__c = (lineItem.TotalPrice * oppty.Probability) / 100;
                theSchedule.RecRevWei__c = (theSchedule.RecognizedRev__c * oppty.Probability)/100;
                theSchedule.DefReWei__c = (theSchedule.DeferredRev__c * oppty.Probability)/100; 
                
                if(lineItem.TotalPrice == 0)
                    theSchedule.Recognized_Quantity__c = 0;    
                else 
                    theSchedule.Recognized_Quantity__c = ((theSchedule.RecognizedRev__c * 100)/lineItem.TotalPrice) * lineItem.Quantity;                          
                
                revenuSchedules.add(theSchedule);
            }
            revreclineItem.RecognizedRev__c = recognizedTotal;
            revreclineItem.DeferredRev__c = recognizableTotal - revreclineItem.RecognizedRev__c;
            revreclineItem.RecRevWei__c = (recognizedTotal * oppty.Probability)/100;
            revreclineItem.DefReWei__c = (revreclineItem.RecognizedRev__c * oppty.Probability)/100;
            revreclineItem.CalculatedAt__c = date.today();
            revreclineItem.TotalRev__c = recognizableTotal;
            revreclineItem.Total_Amt_Wei__c = (recognizableTotal * oppty.Probability)/100;
        }
        return result;                  
    }
    
    /**
     *  @description    :   This method is used to get the transaction date.
     *
     *  @args           :   Date theDate, boolean inCurrentMonth
     *
     *  @return         :   Date
    **/
    private static Date GetTransDateForBlended(Date theDate, boolean inCurrentMonth, RevRecAppSetting__c appSetting) {
      
        Date returnDate = theDate;
        
        if (!inCurrentMonth) returnDate = returnDate.addMonths(1);
        
        //default is first day of the month
        Integer transactionDay = theDate.toStartOfMonth().day();
        
        if (appSetting.Time_of_Month_Selection_Types_tr__c == '1') { //last day of the month
            transactionDay = theDate.toStartOfMonth().addMonths(1).addDays(-1).day();
        } else if (appSetting.Time_of_Month_Selection_Types_tr__c == '2') { // Date of the month
            transactionDay = Integer.valueOf(appSetting.Certain_date_of_month_tr__c);
        } else if (appSetting.Time_of_Month_Selection_Types_tr__c == '3') { //certain weekday of certain week
            Date calculated = RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(theDate, appSetting.Certain_weekday_tr__c, appSetting.Certain_weekday_day_tr__c);
            transactionDay = calculated.day();
        }
        
        returnDate = date.newinstance(returnDate.year(), returnDate.month(), transactionDay);
        
        return returnDate;
    } 
     
    public  Date GetTransDate(Date theDate, boolean inCurrentMonth, RevRecAppSetting__c theSetting) {
        
        Date returnDate = theDate;
        
        if (!inCurrentMonth) returnDate = returnDate.addMonths(1);
        
        //default is first day of the month
        integer transactionDay = theDate.toStartOfMonth().day();
        
        if (theSetting.Time_of_Month_Selection_Types_tr__c == '1') { //last day of the month
            transactionDay = theDate.toStartOfMonth().addMonths(1).addDays(-1).day();
        } else if (theSetting.Time_of_Month_Selection_Types_tr__c == '2') { // Date of the month
            transactionDay = Integer.valueOf(theSetting.Certain_date_of_month_tr__c);
        } else if (theSetting.Time_of_Month_Selection_Types_tr__c == '3') { //certain weekday of certain week
            Date calculated = RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(theDate, theSetting.Certain_weekday_tr__c, theSetting.Certain_weekday_day_tr__c);
            transactionDay = calculated.day();
        }
                
        returnDate = date.newinstance(returnDate.year(), returnDate.month(), transactionDay);
        
        return returnDate;
    }
    
    public String appSettingChecks (RevRecAppSetting__c theSetting, Opportunity oppty, OpportunityStage theStage) {
        
        Boolean shouldContinue = true; 
        
        //Checking for Opportunity type in application setting
        if (theSetting.Opportunity_Type__c != null) {
            
            //Checking if Opportunity's type  is meet the application setting criteria
            if (oppty.Type != null && oppty.Type.length() > 0) {
                if (!theSetting.Opportunity_Type__c.contains(oppty.Type))
                    shouldContinue = false;
            } else 
                shouldContinue = false;
        } 
        //Checking for flag 
        if (!shouldContinue)
            return 'Opportunity Type is not supported by the rule engine';
        
        //Checking for opportunity stage in application setting    
        if (theSetting.Opportunity_Stage__c != null) {
            
            //Checking if opportunity's stage meet the application setting criteria
            if (oppty.StageName != null && oppty.StageName.length() > 0 && theStage != null) {
                if (!theSetting.Opportunity_Stage__c.contains(theStage.Id))
                    shouldContinue = false;
            } else 
                shouldContinue = false;
        } 
        //Checking for flag
        if (!shouldContinue) 
            return 'Opportunity Stage is not supported by the rule engine';
        
        return null;
    }
     
    public void milesCalculation(List<Decimal> recognizableForEachMonths, Integer totalMonths, RevRecProductRule__c overrideRule, Set<String> setMilestoneNames,
                                 Map<String,RevRecProductRuleMilestone__c> mapMileStonesToBeInserted, Integer startDateMonth, Integer startDateYear, Date lastDayOfMonth,
                                 Date startDate, Set<Id> setMilesIds,Integer milesCount, List<RevRecProductRuleMilestone__c> listMileStone, 
                                 OpportunityLineItem li, Decimal probability) {
        
        Decimal actualAmt = 0.00;
        Boolean isLineItemAmtChanged = true;
        
		if(!overrideRule.AM_Manual_Cal__c) { 
            
            //Code added
            if(listMileStone.size() > 0) {
            	for(RevRecProductRuleMilestone__c mile : listMileStone ) {
            		if(overrideRule.Milestone_Type__c == 'amount') {
            			actualAmt += mile.Actual_Amount__c;
            		}
            	}
            	
            	if(actualAmt == li.TotalPrice)
            		isLineItemAmtChanged = false;
            }
                       
    		for (Integer j=0; j < totalMonths; j++) { 
                
                if(overrideRule.Id != null) {
                    
                    //Variables to hold the month values of start date and end date
                    startDateMonth = startDate.addMonths(j).Month();startDateYear = startDate.addMonths(j).Year();
                    
                    lastDayOfMonth = startDate.addMonths(j);
                    
            		if(recognizableForEachMonths.size() > 0) {
                        if(milesCount >  0 && milesCount > j) { 
                            setMilesIds.add(listMileStone[j].Id);
                            
                            if((!setMilestoneNames.contains(Constants.convertNumberToMonthText(startDateMonth)+' - '+String.valueOf(startDateYear))))
                                mapMileStonesToBeInserted.put(Constants.convertNumberToMonthText(startDateMonth)+' - '+String.valueOf(startDateYear) + ' - ' + overrideRule.Id, 
                                                                new RevRecProductRuleMilestone__c(Name = Constants.convertNumberToMonthText(startDateMonth)+' - '+String.valueOf(startDateYear),
                                                                                                    Amount__c = recognizableForEachMonths[j], MileStone_Date__c = lastDayOfMonth,
                                                                                                    Actual_Amount__c = recognizableForEachMonths[j], Id = listMileStone[j].Id,
                                                                                                    Projected_Amount__c = recognizableForEachMonths[j],                                                                                                                                                                                                                 
                                                                                                    Milestone_Name__c = Constants.convertNumberToMonthText(startDateMonth)+' - '+String.valueOf(startDateYear),
                                                                                                    Milestone_Sequence__c = j+1, RevRecProductRule__c = overrideRule.Id,
                                                                                                    Milestone_Date_Source__c = 'MANUAL',
                                                                                                    Percent__c = li.TotalPrice != 0 ? (recognizableForEachMonths[j] *100)/li.TotalPrice : 0.00,
		                                                                                            Actual_Percent__c = li.TotalPrice != 0 ? (recognizableForEachMonths[j] *100)/li.TotalPrice : 0.00,
		                                                                                            Projected_Percent__c = li.TotalPrice != 0 ? (recognizableForEachMonths[j] *100)/li.TotalPrice : 0.00,
		                                                                                            qty__c = li.TotalPrice != 0 ? ((recognizableForEachMonths[j]/li.TotalPrice)*li.Quantity) : 0.00,
			                                                                                        Actual_Qty__c = li.TotalPrice != 0 ? ((recognizableForEachMonths[j]/li.TotalPrice)*li.Quantity) : 0.00,
			                                                                                        Projected_Qty__c = li.TotalPrice != 0 ? ((recognizableForEachMonths[j]/li.TotalPrice)*li.Quantity) : 0.00, 
                                                                                                    Amt_Wei__c = recognizableForEachMonths[j]*probability,
                                                                                                    Act_Amt_Wei__c = recognizableForEachMonths[j]*probability,
                                                                                                    Proj_Amt_Wei__c = recognizableForEachMonths[j]*probability));
                                
                            else {
                                mapMileStonesToBeInserted.remove(Constants.convertNumberToMonthText(startDateMonth)+' - '+String.valueOf(startDateYear));
                                mapMileStonesToBeInserted.put(Constants.convertNumberToMonthText(startDateMonth)+' - '+String.valueOf(startDateYear) + ' - ' + overrideRule.Id, 
                                                                new RevRecProductRuleMilestone__c(Name = Constants.convertNumberToMonthText(startDateMonth)+' - '+String.valueOf(startDateYear),
                                                                                                    Amount__c = recognizableForEachMonths[j], MileStone_Date__c = lastDayOfMonth,
                                                                                                    Actual_Amount__c = recognizableForEachMonths[j], Id = listMileStone[j].Id,
                                                                                                    Projected_Amount__c = recognizableForEachMonths[j],                                                                                                                                                                                                                 
                                                                                                    Milestone_Name__c = Constants.convertNumberToMonthText(startDateMonth)+' - '+String.valueOf(startDateYear),
                                                                                                    Milestone_Sequence__c = j+1, RevRecProductRule__c = overrideRule.Id,
                                                                                                    Milestone_Date_Source__c = 'MANUAL',
                                                                                                    Percent__c = li.TotalPrice != 0 ? (recognizableForEachMonths[j] *100)/li.TotalPrice : 0.00,
		                                                                                            Actual_Percent__c = li.TotalPrice != 0 ? (recognizableForEachMonths[j] *100)/li.TotalPrice : 0.00,
		                                                                                            Projected_Percent__c = li.TotalPrice != 0 ? (recognizableForEachMonths[j] *100)/li.TotalPrice : 0.00,
		                                                                                            qty__c = li.TotalPrice != 0 ? ((recognizableForEachMonths[j]/li.TotalPrice)*li.Quantity) : 0.00,
			                                                                                        Actual_Qty__c = li.TotalPrice != 0 ? ((recognizableForEachMonths[j]/li.TotalPrice)*li.Quantity) : 0.00,
			                                                                                        Projected_Qty__c = li.TotalPrice != 0 ? ((recognizableForEachMonths[j]/li.TotalPrice)*li.Quantity) : 0.00, 
                                                                                                    Amt_Wei__c = recognizableForEachMonths[j]*probability,
                                                                                                    Act_Amt_Wei__c = recognizableForEachMonths[j]*probability,
                                                                                                    Proj_Amt_Wei__c = recognizableForEachMonths[j]*probability));
                            }
                        } else if((!setMilestoneNames.contains(Constants.convertNumberToMonthText(startDateMonth)+' - '+String.valueOf(startDateYear))))
                            mapMileStonesToBeInserted.put(Constants.convertNumberToMonthText(startDateMonth)+' - '+String.valueOf(startDateYear) + ' - ' + overrideRule.Id, 
                                                          new RevRecProductRuleMilestone__c(Name = Constants.convertNumberToMonthText(startDateMonth)+' - '+String.valueOf(startDateYear),
                                                                                            Amount__c = recognizableForEachMonths[j], MileStone_Date__c = lastDayOfMonth,
                                                                                            Actual_Amount__c = recognizableForEachMonths[j],
                                                                                            Projected_Amount__c = recognizableForEachMonths[j],                                                                                                                                                                                                                 
                                                                                            Milestone_Name__c = Constants.convertNumberToMonthText(startDateMonth)+' - '+String.valueOf(startDateYear),
                                                                                            Milestone_Sequence__c = j+1, RevRecProductRule__c = overrideRule.Id,
                                                                                            Milestone_Date_Source__c = 'MANUAL',
                                                                                            Percent__c = li.TotalPrice != 0 ? (recognizableForEachMonths[j] *100)/li.TotalPrice : 0.00,
                                                                                            Actual_Percent__c = li.TotalPrice != 0 ? (recognizableForEachMonths[j] *100)/li.TotalPrice : 0.00,
                                                                                            Projected_Percent__c = li.TotalPrice != 0 ? (recognizableForEachMonths[j] *100)/li.TotalPrice : 0.00,
                                                                                            qty__c = li.TotalPrice != 0 ? ((recognizableForEachMonths[j]/li.TotalPrice)*li.Quantity) : 0.00,
	                                                                                        Actual_Qty__c = li.TotalPrice != 0 ? ((recognizableForEachMonths[j]/li.TotalPrice)*li.Quantity) : 0.00,
	                                                                                        Projected_Qty__c = li.TotalPrice != 0 ? ((recognizableForEachMonths[j]/li.TotalPrice)*li.Quantity) : 0.00, 
                                                                                            Amt_Wei__c = recognizableForEachMonths[j]*probability,
                                                                                            Act_Amt_Wei__c = recognizableForEachMonths[j]*probability,
                                                                                            Proj_Amt_Wei__c = recognizableForEachMonths[j]*probability)); 
                	}
                }  
        	}                   
    	}
    }
    /** This method is used to calculate recognition for amortize milstone rule **/
    public List<Decimal> getRecognigibleFORBR (Date startDate , Date endDate , RevRecProductRule__c overridenRule , Decimal recognigibleAMT , Integer totalMonths, List<Decimal>  recognizableForEachMonths) {
                                     
        Date tempStartDate = startDate;  
        Decimal firstMonthRecognizableByDailyRatio = 0.00;
        Decimal lastMonthRecognizableByDailyRatio = 0.00;
        Integer totalDays = startDate.daysBetween(endDate) + 1;
        Decimal dailyRecognizable = (recognigibleAMT/totalDays).setScale(2);
        Date newStartDate;
        Date newStartDateTemp;
                
        //if totalMonths 0
        if(totalMonths == 0)
            totalMonths = 1;
        
        Decimal monthlyRecognizable = ((recognigibleAMT)/totalMonths);
       
        if(totalMonths > 0) {
                                                
            if(overridenRule != null &&  overridenRule.Divide_By__c  == 'Period') {
                if (overridenRule.Period_or_Exact_Days__c == 'period') {                                            
                    for (Integer j=0; j < totalMonths; j++) {  
                        if(j == 0) 
                            recognizableForEachMonths.add((monthlyRecognizable).setScale(2));
                        else 
                            recognizableForEachMonths.add((monthlyRecognizable).setScale(2));
                    }
                } else if (overridenRule.Period_or_Exact_Days__c == 'exact') {
                    Integer totalDaysInPeriod = 0;
                    for (Integer j=0; j < totalMonths; j++) { 
                        //FOR End schedule
                        if(j == (totalMonths -1)) {
                            //chekin for null
                            if(newStartDateTemp == null)
                                newStartDateTemp = startDate;
                            //Total days in last period
                            totalDaysInPeriod = newStartDateTemp.daysBetween(endDate);
                        } else {
                            //checking for null
                            if(newStartDate == null)
                                newStartDate = startDate;
                            //Calculating total periods 
                            totalDaysInPeriod = newStartDate.daysBetween(newStartDate.addMonths(1));
                            //Start dates
                            newStartDate = newStartDate.addMonths(1);
                            newStartDateTemp = startDate.addMonths(j+1);
                        }                   
                                                                           
                        //Recognized amount
                        if(j == 0)
                            recognizableForEachMonths.add( getPeriodAmount(totalDaysInPeriod,(dailyRecognizable)));
                        else
                            recognizableForEachMonths.add( getPeriodAmount(totalDaysInPeriod,dailyRecognizable));
                    }
                }
            } else if(overridenRule.Divide_By__c != null &&  overridenRule.Divide_By__c  == 'nonProrate') { //2nd option
               
                firstMonthRecognizableByDailyRatio = (dailyRecognizable * startDate.daysBetween(startDate.addMonths(1).toStartOfMonth())).setScale(2);
                lastMonthRecognizableByDailyRatio = (dailyRecognizable * endDate.day()).setScale(2);
                
                if (overridenRule.Period_or_Exact_Days__c == 'period') {
                
                    Decimal actualAmountForAllMonth = 0.00;
                    if(totalMonths > 2)
                        actualAmountForAllMonth = ((recognigibleAMT-firstMonthRecognizableByDailyRatio-lastMonthRecognizableByDailyRatio)/(totalMonths - 2)).setScale(2);
                    else
                        actualAmountForAllMonth = (recognigibleAMT-firstMonthRecognizableByDailyRatio-lastMonthRecognizableByDailyRatio);
                    for (Integer j=0; j < totalMonths; j++) { 
                        if(j==0)
                            recognizableForEachMonths.add(firstMonthRecognizableByDailyRatio);
                        else if(j == (totalMonths-1))
                            recognizableForEachMonths.add(lastMonthRecognizableByDailyRatio);
                        else
                            recognizableForEachMonths.add(actualAmountForAllMonth);
                    }
                } else if (overridenRule.Period_or_Exact_Days__c == 'exact') {
                    
                    totalDays = 0;
                    
                    for (Integer j=1; j < totalMonths-1; j++) {
                        tempStartDate = tempStartDate.addMonths(j);
                        totalDays += Date.daysInMonth(tempStartDate.year(), tempStartDate.month());
                    }
                    
                    tempStartDate = startDate;
                    
                    for (Integer j=0; j < totalMonths; j++) {
                        if(j==0)
                            recognizableForEachMonths.add(firstMonthRecognizableByDailyRatio);
                        else if(j == (totalMonths-1))
                            recognizableForEachMonths.add(lastMonthRecognizableByDailyRatio);
                        else
                            recognizableForEachMonths.add((dailyRecognizable * Date.daysInMonth(tempStartDate.year(), tempStartDate.month())).setScale(2));
                            
                        tempStartDate = tempStartDate.addMonths(1);
                    }
                } 
            } else if(overridenRule.Divide_By__c != null &&  overridenRule.Divide_By__c  == 'Prorate') { //3rd option
                  
                Decimal monthlyRecognizableAmount = 0.00;
                
                if(totalMonths > 1)
                    monthlyRecognizableAmount = ((recognigibleAMT)/(totalMonths-1));
                else
                    monthlyRecognizableAmount = (recognigibleAMT);
                if(overridenRule.Start_Percentage__c != null) 
                    firstMonthRecognizableByDailyRatio = (monthlyRecognizableAmount * (overridenRule.Start_Percentage__c /100)).setScale(2);
                if(overridenRule.End_Percentage__c != null)
                    lastMonthRecognizableByDailyRatio = (monthlyRecognizableAmount * (overridenRule.End_Percentage__c /100)).setScale(2); 
                if (overridenRule.Period_or_Exact_Days__c == 'period') {
                    
                    for (Integer j=0; j < totalMonths; j++) {
                        if(j==0)
                            recognizableForEachMonths.add(firstMonthRecognizableByDailyRatio);
                        else if(j == (totalMonths-1))
                            recognizableForEachMonths.add(lastMonthRecognizableByDailyRatio);
                        else
                            recognizableForEachMonths.add(monthlyRecognizableAmount);
                    }
                    
                } else if (overridenRule.Period_or_Exact_Days__c == 'exact') {
                    
                    totalDays = 0;
                    
                    for (Integer j=1; j < totalMonths-1; j++) { 
                        tempStartDate = tempStartDate.addMonths(j);
                        totalDays += Date.daysInMonth(tempStartDate.year(), tempStartDate.month());
                    }
                    
                    dailyRecognizable = ((recognigibleAMT-(firstMonthRecognizableByDailyRatio + lastMonthRecognizableByDailyRatio))/(totalDays-1)).setScale(2);
                    tempStartDate = startDate;
                    
                    for (Integer j=0; j < totalMonths; j++) { 
                        if(j==0)
                            recognizableForEachMonths.add(firstMonthRecognizableByDailyRatio);
                        else if(j == (totalMonths-1))
                            recognizableForEachMonths.add(lastMonthRecognizableByDailyRatio);
                        else 
                            recognizableForEachMonths.add((dailyRecognizable * Date.daysInMonth(tempStartDate.year(), tempStartDate.month())).setScale(2));
                        tempStartDate = tempStartDate.addMonths(1);
                    }
                }
            }
        }
        
        //Loop over recognizableForEachMonths
        if(recognizableForEachMonths.size() > 0) {
            
            Decimal sumOfAmt = 0.00;
            
            //Looping
            for(Decimal recAmt : recognizableForEachMonths) 
                sumOfAmt += recAmt;
            
            if(sumOfAmt != recognigibleAMT ) {
                if(overridenRule.Divide_By__c  != 'Prorate')
                    recognizableForEachMonths[totalMonths-1] += (recognigibleAMT - sumOfAmt);
                else {
                    if(totalMonths >= 2)
                        recognizableForEachMonths[totalMonths-2] += (recognigibleAMT - sumOfAmt);
                }
            }                                   
        }
        
        //In case if start and end date in same month
        if(startDate.year() == endDate.year()) {
            if(startDate.month() == endDate.month()) {
                recognizableForEachMonths = new List<Decimal>();
                recognizableForEachMonths.add(recognigibleAMT);
            }
            if(totalMonths == 1) {
                recognizableForEachMonths = new List<Decimal>();
                recognizableForEachMonths.add(recognigibleAMT);
            }            
        }
        return recognizableForEachMonths;
    }
    
    public void calculateAmountForBR(Map<String, RevRecOpportunityLineItemSchedule__c> mapScheduleAccordingToMonthAndYear,
                                      Map<String, List<RevRecScheduleCategory__c>> mapMonthYearScheduleCategories, 
                                      Map<String,List<Decimal>> mapRecognizableForEachMonthsForBR, 
                                      Decimal totalQty, Decimal probability, List<OpportunityLineItem> lineItems) {
    	        
        Map<String, Decimal> mapTotalAmountForCat = new Map<String, Decimal>();
         
        for(String mapKey : mapRecognizableForEachMonthsForBR.keySet()){
            Decimal totalAmt = 0.0;   
            for(Decimal dec : mapRecognizableForEachMonthsForBR.get(mapKey))
                totalAmt += dec;
            mapTotalAmountForCat.put(mapKey, totalAmt);
        }  
                                          
        for(String mapKey : mapMonthYearScheduleCategories.keySet()) {
        	
        	List<String> lineitemIdAfterSplit = mapKey.split('-');
        	String lineItemId = lineitemIdAfterSplit[0];
        	
            for(RevRecScheduleCategory__c cat : mapMonthYearScheduleCategories.get(mapKey)) {
                if(mapRecognizableForEachMonthsForBR.containsKey(lineItemId + '-' + cat.Category_Name__c)) {
                    List<Decimal> amtList = mapRecognizableForEachMonthsForBR.get(lineItemId + '-' + cat.Category_Name__c);
                    if(amtList.size() > 0) {
                        cat.Amount1__c = amtList[0];
                        cat.Deferred_Amount__c = mapTotalAmountForCat.get(lineItemId + '-' + cat.Category_Name__c) - cat.Amount1__c;
                        if(cat.Deferred_Amount__c != null)
                            cat.Def_Amt_Wei__c = cat.Deferred_Amount__c * probability;
                        if(cat.Amount1__c != null)
                            cat.Rec_Amt_Wei__c = cat.Amount1__c * probability;
                        amtList.remove(0);
                        mapRecognizableForEachMonthsForBR.remove(lineItemId + '-' + cat.Category_Name__c);
                        mapRecognizableForEachMonthsForBR.put(lineItemId + '-' + cat.Category_Name__c, amtList);
                    } 
                } 
            } 
        } 
        
        Decimal recAmt = 0.0;
        Decimal defAmt = 0.0; 
        Decimal totalAmount = 0.0;                                 
        for(String mapKey : mapScheduleAccordingToMonthAndYear.keySet()) {
        	List<String> lineitemIdAfterSplit = mapKey.split('-');
        	String lineItemId = lineitemIdAfterSplit[0];
        	for(OpportunityLineItem lineItem : lineItems) {
        		
        		if(lineItem.Id == lineItemId.trim())
        			totalAmount = lineItem.TotalPrice;
        	}
            RevRecOpportunityLineItemSchedule__c sch = mapScheduleAccordingToMonthAndYear.get(mapKey);
            Decimal revRecTotal = 0.0;
            for(RevRecScheduleCategory__c cat : mapMonthYearScheduleCategories.get(mapKey)) {
            	revRecTotal += cat.Amount1__c; 
            }
                
            recAmt += revRecTotal;
            sch.RecognizedRev__c = revRecTotal;
            sch.RecRevWei__c = revRecTotal * probability;
            sch.DeferredRev__c = totalAmount - sch.RecognizedRevTotal__c;
            sch.DefReWei__c = sch.DeferredRev__c * probability;
        } 
    }
     
    public void calMileWithCorporateField(List<RevRecProductRuleMilestone__c> mileStonesToBeInserted, Opportunity opp, Utility utl) {
        
        Boolean isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
        Decimal pro = opp.Probability/100;
        
        for(RevRecProductRuleMilestone__c miles : mileStonesToBeInserted) {
            
            if(isMultiCurrencyEnabled) {
                if(miles.Amount__c != null) 
                    miles.Cor_Amt_Wei__c = (utl.corporateCurrencyCalculation(String.valueOf(opp.get('CurrencyIsoCode')), miles.Amount__c)) * pro;
                else 
                    miles.Cor_Amt_Wei__c = 0.00; 
                
                if(miles.Actual_Amount__c != null)
                    miles.Cor_Act_Amt_Wei__c = (utl.corporateCurrencyCalculation(String.valueOf(opp.get('CurrencyIsoCode')), miles.Actual_Amount__c)) * pro;    
                else 
                    miles.Cor_Act_Amt_Wei__c = 0.00; 
                
                if(miles.Projected_Amount__c != null)
                    miles.Cor_Prj_Amt_Wei__c = (utl.corporateCurrencyCalculation(String.valueOf(opp.get('CurrencyIsoCode')), miles.Projected_Amount__c)) * pro;    
                else 
                    miles.Cor_Prj_Amt_Wei__c = 0.00; 
            }
        }
    }
    
    public void calRRLIWithCorporateField(List<RevRecOpportunityLineItem__c> revRecLineItems, Opportunity opp, Utility utl) {
        
        Boolean isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
        Decimal pro = opp.Probability/100;
        
        for(RevRecOpportunityLineItem__c rroli : revRecLineItems) {
            
            if(isMultiCurrencyEnabled) {
                if(rroli.DeferredRev__c != null) 
                    rroli.Cor_Def_Prod_Wei__c = (utl.corporateCurrencyCalculation(String.valueOf(opp.get('CurrencyIsoCode')), rroli.DeferredRev__c)) * pro;
                else 
                    rroli.Cor_Def_Prod_Wei__c = 0.00; 
                
                if(rroli.RecognizedRev__c != null)
                    rroli.Cor_Rec_Rev_Wei1__c = (utl.corporateCurrencyCalculation(String.valueOf(opp.get('CurrencyIsoCode')), rroli.RecognizedRev__c)) * pro;    
                else 
                    rroli.Cor_Rec_Rev_Wei1__c = 0.00; 
                
                if(rroli.ResAmtWei__c != null)
                    rroli.Cor_Residual_Amt_Wei__c = (utl.corporateCurrencyCalculation(String.valueOf(opp.get('CurrencyIsoCode')), rroli.ResAmtWei__c)) * pro;    
                else 
                    rroli.Cor_Residual_Amt_Wei__c = 0.00;
                
                if(rroli.TotalRev__c != null)
                    //rroli.Cor_Total_Amt_Wei1__c = (utl.corporateCurrencyCalculation(String.valueOf(opp.get('CurrencyIsoCode')), rroli.TotalRev__c)) * pro;    
                	rroli.Cor_Total_Amt1__c = (utl.corporateCurrencyCalculation(String.valueOf(opp.get('CurrencyIsoCode')), rroli.TotalRev__c)) * pro;   
                else 
                    //rroli.Cor_Total_Amt_Wei1__c = 0.00;
                    rroli.Cor_Total_Amt1__c = 0.00;
                //-----------------------------------
                if(rroli.Total_Amt_Wei__c != null)
                	rroli.Cor_Total_Amt_Wei1__c = (utl.corporateCurrencyCalculation(String.valueOf(opp.get('CurrencyIsoCode')), rroli.Total_Amt_Wei__c)) * pro;   
                else 
                    rroli.Cor_Total_Amt_Wei1__c = 0.00;
                if(rroli.Allocated_Amount__c != null)
                	rroli.Cor_Allocated_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(opp.get('CurrencyIsoCode')), rroli.Allocated_Amount__c)) * pro;   
                else 
                    rroli.Cor_Allocated_Amt__c = 0.00;
                if(rroli.ResidualAmount__c != null)
                	rroli.Cor_Res_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(opp.get('CurrencyIsoCode')), rroli.ResidualAmount__c)) * pro;   
                else 
                    rroli.Cor_Res_Amt__c = 0.00;
            }
        }
    }
    
    public void calProCatWithCorporateField(List<RevRecProductRuleCategory__c> rrProCat, Opportunity opp, Utility utl) {
        
        Boolean isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
        Decimal pro = opp.Probability/100;
        
        for(RevRecProductRuleCategory__c prdCat : rrProCat) {
            
            //If true the do this 
            if(isMultiCurrencyEnabled) {
                
                if(prdCat.Actual_Deferred__c != null) 
                    prdCat.Cor_Act_Def_Wei__c = ((utl.corporateCurrencyCalculation(String.valueOf(opp.get('CurrencyIsoCode')), prdCat.Actual_Deferred__c))* pro);
                else 
                    prdCat.Cor_Act_Def_Wei__c = 0.00;
                
                if(prdCat.Deferred_Amount__c != null) 
                    prdCat.Cor_Def_Amt_Wei__c = ((utl.corporateCurrencyCalculation(String.valueOf(opp.get('CurrencyIsoCode')), prdCat.Deferred_Amount__c))* pro);
                else
                    prdCat.Cor_Def_Amt_Wei__c = 0.00;
                
                if(prdCat.Recognized_Amount__c != null)
                    prdCat.Cor_Rec_Amt_Wei__c = ((utl.corporateCurrencyCalculation(String.valueOf(opp.get('CurrencyIsoCode')), prdCat.Recognized_Amount__c))* pro);
                else
                    prdCat.Cor_Rec_Amt_Wei__c = 0.00;
            }
        }
    }
    
    public void calOLISchWithCorporateField(List<RevRecOpportunityLineItemSchedule__c> allSchedule, Opportunity opp, Utility utl) {
        
        Boolean isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
        Decimal pro = opp.Probability/100;
        
        for(RevRecOpportunityLineItemSchedule__c sch : allSchedule) {
            
            //If true the do this 
            if(isMultiCurrencyEnabled) {
                
                if(sch.DeferredRev__c != null) 
                    sch.Corp_Def_Rev_Wei__c = (utl.corporateCurrencyCalculation(String.valueOf(opp.get('CurrencyIsoCode')), sch.DeferredRev__c)) * pro;
                else 
                    sch.Corp_Def_Rev_Wei__c = 0.00;
                
                //Checking for null
                if(sch.RecognizedRev__c != null) 
                    sch.Cor_Rec_Rev_Wei__c = (utl.corporateCurrencyCalculation(String.valueOf(opp.get('CurrencyIsoCode')), sch.RecognizedRev__c)) * pro;
                else 
                    sch.Cor_Rec_Rev_Wei__c = 0.00;
                
                //Checking for null
                if(sch.LineItemAmountTotal__c != null) 
                    sch.Cor_LI_Amt_Total_Wei__c = (utl.corporateCurrencyCalculation(String.valueOf(opp.get('CurrencyIsoCode')), sch.LineItemAmountTotal__c)) * pro;
                else 
                    sch.Cor_LI_Amt_Total_Wei__c = 0.00;
                
                //Checking for null
                if(sch.RecognizedRevTotal__c != null) 
                    sch.Cor_Rec_Total_Amt_Wei__c = (utl.corporateCurrencyCalculation(String.valueOf(opp.get('CurrencyIsoCode')), sch.RecognizedRevTotal__c)) * pro;
                else
                    sch.Cor_Rec_Total_Amt_Wei__c = 0.00;
                
                //Checking for null
                if(sch.ResidualAmountTotal__c != null) 
                    sch.Cor_Res_Total_Amt_Wei__c = (utl.corporateCurrencyCalculation(String.valueOf(opp.get('CurrencyIsoCode')), sch.ResidualAmountTotal__c)) * pro;
                else 
                    sch.Cor_Res_Total_Amt_Wei__c = 0.00;
            }
        }
    }
    
    public void calSchCatWithCorporateField(List<RevRecScheduleCategory__c> scheduleCats, Opportunity opp, Utility utl) {
        
        Boolean isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
        Decimal pro = opp.Probability/100;
        
        for(RevRecScheduleCategory__c sch : scheduleCats) {
            
            //If true the do this 
            if(isMultiCurrencyEnabled) {
                
                if(sch.Deferred_Amount__c != null) 
                    sch.Cor_Def_Amt_Wei__c = (utl.corporateCurrencyCalculation(String.valueOf(opp.get('CurrencyIsoCode')), sch.Deferred_Amount__c)) * pro;
                else 
                    sch.Cor_Def_Amt_Wei__c = 0.00;
                
                //Checking for null
                if(sch.Amount1__c != null) 
                    sch.Cor_Rec_Amt_Wei__c = (utl.corporateCurrencyCalculation(String.valueOf(opp.get('CurrencyIsoCode')), sch.Amount1__c)) * pro;
                else 
                    sch.Cor_Rec_Amt_Wei__c = 0.00;
            }
        }
    }
    
    public void rroliScheduleWeightedValues(Map<String, RevRecOpportunityLineItemSchedule__c> mapScheduleAccordingToMonthAndYear, Decimal probability, Id rroliId) {
        
        //Loop over all Blended Schedules and calculate deferred amount again
        for(RevRecOpportunityLineItemSchedule__c schedule : mapScheduleAccordingToMonthAndYear.values()) {
            
            //Checking for conditions and then put values   
            if(schedule.RevRecOpportunityLineItem__c == rroliId) {
                
                schedule.DefReWei__c = schedule.DeferredRev__c * probability;
                schedule.RecRevWei__c = schedule.RecognizedRev__c * probability;
                schedule.Rec_Total_Amt_Wei__c = schedule.RecognizedRevTotal__c * probability;
                schedule.LI_Amt_Total_Wei__c = schedule.LineItemAmountTotal__c * probability;
            }
        }
    }

    public Map<Id, Map<String, RevRecProductRuleMilestone__c>> newMilesCalculation(List<Decimal> recognizableForEachMonths, Integer totalMonths, 
                                    RevRecProductRule__c overrideRule, 
                                    Map<Id, Map<String, RevRecProductRuleMilestone__c>> mapToCompareProRuleIdWithMapOfMiles,
                                    Integer startDateMonth, Integer startDateYear, 
                                    Date lastDayOfMonth, Date startDate,  
                                    Double totalAmt, Decimal probability) {
                          
        Map<String, RevRecProductRuleMilestone__c> mapMilesNameWithMiles = new Map<String, RevRecProductRuleMilestone__c>();
         
		System.debug('@@@ recognizableForEachMonths size' +recognizableForEachMonths.size()); 
		System.debug('@@@ totalMonths' +totalMonths);
        for (Integer j=0; j < totalMonths; j++) { 
           
            //Variables to hold the month values of start date and end date
            startDateMonth = startDate.addMonths(j).Month();startDateYear = startDate.addMonths(j).Year();lastDayOfMonth = startDate.addMonths(j);
            lastDayOfMonth = startDate.addMonths(j);
            
                if(!mapMilesNameWithMiles.containsKey(Constants.convertNumberToMonthText(startDateMonth)+' - '+String.valueOf(startDateYear))) {
                mapMilesNameWithMiles.put(Constants.convertNumberToMonthText(startDateMonth)+' - '+String.valueOf(startDateYear),
                                          new RevRecProductRuleMilestone__c(Name = Constants.convertNumberToMonthText(startDateMonth)+' - '+String.valueOf(startDateYear),
                                                                            Amount__c = recognizableForEachMonths[j], MileStone_Date__c = lastDayOfMonth,
                                                                            Actual_Amount__c = recognizableForEachMonths[j], 
                                                                            Projected_Amount__c = recognizableForEachMonths[j],                                                                                                                                                                                                                 
                                                                            Milestone_Name__c = Constants.convertNumberToMonthText(startDateMonth)+' - '+String.valueOf(startDateYear),
                                                                            Milestone_Sequence__c = j+1, RevRecProductRule__c = overrideRule.Id,
                                                                            Milestone_Date_Source__c = 'MANUAL',
                                                                            Percent__c = totalAmt != 0 ? (recognizableForEachMonths[j] *100)/totalAmt : 0.00,
                                                                            Actual_Percent__c = totalAmt != 0 ? (recognizableForEachMonths[j] *100)/totalAmt : 0.00,
                                                                            Projected_Percent__c = totalAmt != 0 ? (recognizableForEachMonths[j] *100)/totalAmt : 0.00,
                                                                            qty__c = totalAmt != 0 ? (recognizableForEachMonths[j]/totalAmt) : 0.00,
                                                                            Actual_Qty__c = totalAmt != 0 ? (recognizableForEachMonths[j]/totalAmt) : 0.00,
                                                                            Projected_Qty__c = totalAmt != 0 ? (recognizableForEachMonths[j]/totalAmt) : 0.00, 
                                                                            Amt_Wei__c = recognizableForEachMonths[j]*probability,
                                                                            Act_Amt_Wei__c = recognizableForEachMonths[j]*probability,
                                                                            Proj_Amt_Wei__c = recognizableForEachMonths[j]*probability));
                                       
            }
             
            if(!mapToCompareProRuleIdWithMapOfMiles.containsKey(overrideRule.Id))
                mapToCompareProRuleIdWithMapOfMiles.put(overrideRule.Id, mapMilesNameWithMiles);
        } 
            
        return mapToCompareProRuleIdWithMapOfMiles;
    }
    
    public void rrliCalculation(RevRecOpportunityLineItem__c rroli, OpportunityLIneItem li, Decimal totalRecAmount,
                                Decimal probability, RevRecProductRule__c overriddenRule) {
        
        //-----------
        if(overriddenRule.Id == null) {
        	rroli.DeferredRev__c = li.TotalPrice - totalRecAmount;
        	rroli.RecognizedRev__c = totalRecAmount;
        } else {
        	rroli.DeferredRev__c = li.TotalPrice - rroli.RecognizedRev__c;
         	rroli.RecognizedRev__c = rroli.RecognizedRev__c;
        }
        //rroli.DeferredRev__c = li.TotalPrice - totalRecAmount;
        //rroli.RecognizedRev__c = totalRecAmount;
        rroli.DefReWei__c = rroli.DeferredRev__c * probability;
        rroli.RecRevWei__c = rroli.RecognizedRev__c * probability;
        rroli.CalculatedAt__c = Date.today();
        if(li.TotalPrice > 0) {
        	rroli.Allocated__c = ((rroli.Allocated__c != null ? rroli.Allocated__c : 0.00) * 100 / li.TotalPrice);
			rroli.Remaining_Percentage__c = (100 - rroli.Allocated__c).setScale(2);
        	rroli.Remaining_Amount__c = ((rroli.Remaining_Percentage__c * li.TotalPrice)/100).setScale(2);
			rroli.Remaining_Qty__c = (rroli.Remaining_Amount__c / (li.TotalPrice/li.Quantity)).setScale(2);
        }
        else {
            rroli.Allocated__c = 0.00;
            rroli.Remaining_Amount__c = 0.00;
    		rroli.Remaining_Percentage__c = 0.00;
    		rroli.Remaining_Qty__c = 0.00;
        }
    }
    
    public void rrliRemainingCalc(OpportunityLineItem lineItem, RevRecOpportunityLineItem__c revReclineItem, 
								  List<RevRecProductRuleMilestone__c> productMilestones, string milestype,Double recognizableTotal) {
    	
        if(lineItem.TotalPrice > 0) { 
        	
        	//revreclineItem.Allocated__c = (recognizedTotalForREvRec).setScale(2);
        	if(revreclineItem.Allocated__c > 100)
        		revreclineItem.Allocated__c = 100; 
        		
	        revreclineItem.Remaining_Percentage__c = 100 - revreclineItem.Allocated__c;
	    	revreclineItem.Remaining_Amount__c = ((revreclineItem.Remaining_Percentage__c * lineItem.TotalPrice)/100).setScale(2);
	        revreclineItem.Remaining_Qty__c = (revreclineItem.Remaining_Amount__c / (lineItem.TotalPrice/lineItem.Quantity)).setScale(2);
    	}
    	else {
    		revreclineItem.Allocated__c = 0.00;
    		revreclineItem.Remaining_Amount__c = 0.00;
    		revreclineItem.Remaining_Percentage__c = 0.00;
    		revreclineItem.Remaining_Qty__c = 0.00;
    	}
    }
    
    public void rrliCalcForSingle(Date startDate, RevRecOpportunityLineItem__c revreclineItem, OpportunityLineItem lineItem) {
    	
    	if(startDate == null) {
			revreclineItem.Allocated__c = 0;
			revreclineItem.Remaining_Amount__c = (lineItem.TotalPrice).setScale(2);
			revreclineItem.Remaining_Percentage__c= 100;
			revreclineItem.Remaining_Qty__c = (lineItem.Quantity).setScale(2);
    	}
        else {
        	revreclineItem.Allocated__c = 100;
        	revreclineItem.Remaining_Amount__c = 0;
			revreclineItem.Remaining_Percentage__c= 0;
			revreclineItem.Remaining_Qty__c = 0;
        }
    }
    
    public void rrliCalcForAmortize(Date startDate, Date endDate, RevRecOpportunityLineItem__c revreclineItem, OpportunityLineItem lineItem) {
    	
    	if(startDate == null || endDate == null) {
    		revreclineItem.Allocated__c = 0; 
    		revreclineItem.Remaining_Amount__c = (lineItem.TotalPrice).setScale(2);
			revreclineItem.Remaining_Percentage__c= 100;
			revreclineItem.Remaining_Qty__c = (lineItem.Quantity).setScale(2);
    	}
        else {
            revreclineItem.Allocated__c = 100;
            revreclineItem.Remaining_Amount__c = 0;
			revreclineItem.Remaining_Percentage__c= 0;
			revreclineItem.Remaining_Qty__c = 0;
        }
    }
    
    public String showErrorAndAdjustRevenueButtons(Utility utl, Opportunity theOppty, Boolean isMultiCurrencyEnabled, Boolean isShowAdjuctAndPricingButton, List<RevRecProductRuleMilestone__c> revRecProductRuleMilestones, 
												RevRecProductRule__c overrideRule, RevRecAppSetting__c theSetting, OpportunityLineItem lineItem, Decimal actualAmount, Decimal manualAmount, Decimal amount, Decimal residualAmount, Boolean hideErrorOnSave,
												Decimal actualPercent, Decimal actualQty) {
    	
    	String msg = '';
                                                    
    	for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones) {
                     
            //For AM
            if (overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE) {
                
                if(overrideRule.Milestone_Type__c == 'amount') {
                	//Checking for Null
		            if(item.Actual_Amount__c != null) 
		                actualAmount += item.Actual_Amount__c;
                } else if(overrideRule.Milestone_Type__c == 'percent') {
                	//Checking for Null
	                if(item.Actual_Percent__c != null) 
	                    actualPercent += item.Actual_Percent__c;
                } else if(overrideRule.Milestone_Type__c == 'qty') {
                	//Checking for Null
	                if(item.Actual_Qty__c != null) 
	                    actualQty += item.Actual_Qty__c;
                }
                
                if(item.Projected_Amount__c != null)
                    manualAmount += item.Projected_Amount__c;
                 
                //Code modified -  (07/10/2017) - Check if multi currency enabled in org or not
                //If true the do this 
                if(isMultiCurrencyEnabled) {  
                    
                    if(item.Amount__c != null) {
                        item.Converted_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), item.Amount__c)).replace('<br/>', '');
                        item.Cor_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(theOppty.get('CurrencyIsoCode')), item.Amount__c));
                    } else {
                        item.Converted_Amount__c = theOppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + theOppty.get('CurrencyIsoCode') + ' 0.00 )';
                        item.Cor_Amt__c = 0.00;
                    }
                    if(item.Actual_Amount__c != null) {
                        item.Converted_Actual_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), item.Actual_Amount__c)).replace('<br/>', '');
                        item.Cor_Act_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(theOppty.get('CurrencyIsoCode')), item.Actual_Amount__c));
                    } else {
                        item.Converted_Actual_Amount__c = theOppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + theOppty.get('CurrencyIsoCode') + ' 0.00 )';
                        item.Cor_Act_Amt__c = 0.00;
                    }
                    if(item.Projected_Amount__c != null) {
                        item.Converted_Sales_Manual_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), item.Projected_Amount__c)).replace('<br/>', '');
                        item.Cor_Prj_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(theOppty.get('CurrencyIsoCode')), item.Projected_Amount__c));
                    } else {
                        item.Converted_Sales_Manual_Amount__c = theOppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + theOppty.get('CurrencyIsoCode') + ' 0.00 )';
                        item.Cor_Prj_Amt__c = 0.00;
                    }
                } 
             }
    	}
    	        
        //Code added to by pass amotized milestone validation - 06/23/2017
        if(theSetting.Validate_Amortized_Milestones_Against_Li__c) {
           msg = '';
            if(overrideRule.Milestone_Type__c == 'amount') {
                System.debug('@@@ actualAmount.setScale(2)' +actualAmount.setScale(2));
                System.debug('@@@ @@@' +lineItem.TotalPrice);
                System.debug('@@@ lineItem.TotalPrice' +(((lineItem.TotalPrice-residualAmount)/lineItem.TotalPrice)*100));
                System.debug('@@@ deiff' +((actualAmount/lineItem.TotalPrice)*100));
	            //Checking for the condition if total actual amount is greater than Opportunity amount
	            if(actualAmount.setScale(2) > (lineItem.TotalPrice - residualAmount).setScale(2) ) {
	              
	                msg = Constants.WARNING_MESSAGE_ACTUAL_AMOUNT_IS_GREATER_THAN_ACTUAL+'-false';
	                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Constants.WARNING_MESSAGE_ACTUAL_AMOUNT_IS_GREATER_THAN_ACTUAL)); 
	            }  
	        
	            //Checking for the condition if total actual amount is less than Opportunity amount
	            if(actualAmount.setScale(2) < (lineItem.TotalPrice - residualAmount).setScale(2) ) {
	               
	                if(!hideErrorOnSave) {
	                    msg = Constants.WARNING_MESSAGE_ACTUAL_AMOUNT_IS_LESS_THAN_ACTUAL+'-'+hideErrorOnSave;
	                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Constants.WARNING_MESSAGE_ACTUAL_AMOUNT_IS_LESS_THAN_ACTUAL)); 
	                }
	            }
            } else if(overrideRule.Milestone_Type__c == 'qty') {
           		//Checking for the condition if total actual qty is greater than Opportunity amount
	            if(actualQty.setScale(2) > (lineItem.Quantity)) {
	                    
	                msg = Constants.WARNING_MESSAGE_ACTUAL_AMOUNT_IS_GREATER_THAN_ACTUAL+'-false';
	                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Constants.WARNING_MESSAGE_ACTUAL_AMOUNT_IS_GREATER_THAN_ACTUAL)); 
	            }  
	         
	            //Checking for the condition if total actual amount is less than Opportunity amount
	            if(actualQty.setScale(2) < (lineItem.Quantity)) {
	               
	                if(!hideErrorOnSave) {
	                    msg = Constants.WARNING_MESSAGE_ACTUAL_AMOUNT_IS_LESS_THAN_ACTUAL+'-'+hideErrorOnSave;
	                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Constants.WARNING_MESSAGE_ACTUAL_AMOUNT_IS_LESS_THAN_ACTUAL)); 
	                }
	            } 
           	} else if(overrideRule.Milestone_Type__c == 'percent') {  
           		//Checking for the condition if total actual percent is greater than Opportunity amount
	            if(actualPercent.setScale(2) > 100) {
	                    
	                msg = Constants.WARNING_MESSAGE_ACTUAL_AMOUNT_IS_GREATER_THAN_ACTUAL+'-false';
	                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Constants.WARNING_MESSAGE_ACTUAL_AMOUNT_IS_GREATER_THAN_ACTUAL)); 
	            }  
	        
	            //Checking for the condition if total actual amount is less than Opportunity amount
	            if(actualPercent.setScale(2) <100) {
	               
	                if(!hideErrorOnSave) {
	                    msg = Constants.WARNING_MESSAGE_ACTUAL_AMOUNT_IS_LESS_THAN_ACTUAL+'-'+hideErrorOnSave;
	                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Constants.WARNING_MESSAGE_ACTUAL_AMOUNT_IS_LESS_THAN_ACTUAL)); 
	                }
	            } 
           	}
            /*if(manualAmount >  lineItem.TotalPrice ) {
                if(manualAmount - lineItem.TotalPrice >= 1) {
                    
                    msg = Constants.WARNING_MESSAGE_SALE_AMOUNT_IS_GREATER_THAN_ACTUAL;
                    //isShowAdjuctAndPricingButton = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, msg ));
                } 
            }*/
   		} 
   		return msg; 
	}
	
	public Decimal reCalculationForAM(List<RevRecProductRuleMilestone__c> listMileStone, Decimal totalRecog, Decimal total, Decimal totalDistributedAmount, Decimal amountDist) {
		
		if(listMileStone.size() > 0) {
    		for(RevRecProductRuleMilestone__c milestone : listMileStone) {
        		total += milestone.Actual_Amount__c;
				if(milestone.Milestone_Date__c < Date.today()) 
    				totalRecog +=  milestone.Actual_Amount__c;
        	}
        	if(total != totalDistributedAmount)
        		totalDistributedAmount = total;
        	else
        		totalDistributedAmount = amountDist; 
        }
        return totalDistributedAmount;
	}
	
	public String calculateAmountInStringFormat(Decimal amountToConvert) {
		String convertedAmount = '';
		
		if(amountToConvert != null) {
			if(amountToConvert > 0.00 && amountToConvert < 1000.00) 
				convertedAmount = String.valueOf(amountToConvert);
			else if(amountToConvert >= 1000.00 && amountToConvert < 1000000.00) 
	        	convertedAmount = String.valueOf((amountToConvert/1000).setScale(2)) + 'K';
	        else if(amountToConvert >= 1000000.00 && amountToConvert < 1000000000.00) 
	        	convertedAmount = String.valueOf((amountToConvert/1000000).setScale(2)) + 'M';
	        else if(amountToConvert > 1000000000.00)
	        	convertedAmount = String.valueOf((amountToConvert/1000000000).setScale(2)) + 'B';
            else
                convertedAmount = '0.00';
		}
		return convertedAmount;
	}
   
}