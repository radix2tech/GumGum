/**
 * MC, RA, 07/15/2020
 * @description: Helper class for OLI Automation i.e largely trigger driven 
 * when new OLIs are inserted. 
 */
public class MC_OLIAutomationHelper {
    
    // prevent cyclic updates
    public static boolean hasExecuted = false;
    
    // in before insert set opps recalculate flag to true
    public static void setOppToReprocess(Set<Id> oppIds) {
        List<Opportunity> opps = new List<Opportunity>();
        for(Id oppId: oppIds) {
            opps.add(new Opportunity(id=oppId, Re_calculate_Products__c=true));
        }
        update opps;
    }
    
    //@future
    public static void process(Set<Id> oppIds) {
        // placeholder 
        Map<Id, OpportunityLineItem> placeholderOLIs = new Map<Id, OpportunityLineItem>();
        Set<Id> placeholderOLIIds = new Set<Id>();
        Map<Id, List<OpportunityLineItem>> newOLIs = new Map<Id, List<OpportunityLineItem>>();
        
        // query all olis for the affected opps that are not processed
        Map<Id, OpportunityLineItem> allOLIs = new Map<Id, OpportunityLineItem>(
                [SELECT id, Unit_Price__c, UnitPrice, Processing_Status__c, 
                 TotalPrice, OpportunityId, Pricing__c, Quantity, End_Date__c,
                 Start_Date__c, Product2.Name
                    FROM OpportunityLineItem 
                    WHERE opportunityId=:oppIds 
                    AND Processing_Status__c != 'Processed'
                ]);
        System.debug('allOLIs==>'+allOLIs);
        for(OpportunityLineItem oli: allOLIs.values()) {
            if(oli.Product2.Name == 'Placeholder') {
                OpportunityLineItem plcholder = placeholderOLIs.get(oli.OpportunityId);
                placeholderOLIs.put(oli.OpportunityId, oli);
                placeholderOLIIds.add(oli.id);
            }            
        }
        // capture placeholder lines first
        for(OpportunityLineItem oli: allOLIs.values()) {
            System.debug('oli==>'+oli);
            OpportunityLineItem placeholder = placeholderOLIs.get(oli.OpportunityId);
            if(oli.Processing_Status__c == 'New' && isDateInPrevQuarter(oli.Start_Date__c, Date.Today())) {
                List<OpportunityLineItem> olis = newOLIs.get(oli.OpportunityId);
                if(olis == null) {
                    olis = new List<OpportunityLineItem>();                    
                }
                olis.add(oli);
                newOLIs.put(oli.OpportunityId, olis);
            }
            
        }
        system.debug('allOLIs==>'+allOLIs);
        system.debug('placeholderOLIs==>'+placeholderOLIs);
        system.debug('newOLIs==>'+newOLIs);
        
        // set the right pricing, this was inherited from EB_OpportunityProductExt
        calculatePricing(placeholderOLIs.values());
        Map<Id, Double> mapOLIAmount = new Map<Id, Double>();
        for(OpportunityLineItem oli: placeholderOLIs.values()) {
            mapOLIAmount.put(oli.id, oli.TotalPrice);
        }
        for(Id oppId: placeholderOLIs.keyset()) {
            if(newOLIs.get(oppId) == null) continue;
            for(OpportunityLineItem oli: newOLIs.get(oppId)){
                if(oli.Product2.Name != 'Placeholder') {
                    // get placeholder line for this 
                    OpportunityLineItem plcholder = placeholderOLIs.get(oli.OpportunityId);
                
                    // reduce the total price and this will be used to rebuild price schedule if it exist on placeholder line
                    plcHolder.TotalPrice -= oli.TotalPrice;
                
                    // set new olis to processed
                    oli.Processing_Status__c = 'Processed';
                    // start date should be next month
                    plcHolder.Start_Date__c = Date.newInstance(Date.today().year(), Date.today().month(), 1);
                }
            }
        }
        System.debug('>>>plcHolder: ' + placeholderOLIs);
        
        // prevent cycle updates
        hasExecuted = true;                
        
        // reestablish schedules.
        List<OpportunityLineItemSchedule> olis = [SELECT Id FROM OpportunityLineItemSchedule WHERE OpportunityLineItemId = : placeholderOLIIds];
        if(olis.size() > 0) {
            Database.DeleteResult[] results = database.delete(olis,false);
            // check error
            boolean allSuccess = true;
            for(Database.DeleteResult result: results) {
                
                if(!result.isSuccess()) {
                    allSuccess = false;
                }
            }
            if(allSuccess) {
                establishSchedule(placeholderOLIs.values());
            }
        }
        
        // reset the unit price which may have been adjusted due to the schedules
        for(OpportunityLineItem item: placeholderOLIs.values()) {
            item.unitPrice = item.TotalPrice;
            item.unit_price__c = item.UnitPrice;
            //item.TotalPrice = mapOLIAmount.get(item.id);
        }
        database.update(allOLIs.values(),false);        
        
        // set opp for updates
        List<Opportunity> opps = new List<Opportunity>();
        for(OpportunityLineItem oli: placeholderOLIs.values()) {
            opps.add(new Opportunity(id=oli.OpportunityId, Re_calculate_Products__c=false));
        }
        update opps;
    }
    
    private static void calculatePricing(List<OpportunityLineItem> oppLineItems) {
        for(OpportunityLineItem oppLineItem: oppLineItems) {
            if (oppLineItem.Pricing__c == 'VCPM' || oppLineItem.Pricing__c == 'CPM') {
                System.debug('VCPM or CPM');
                System.debug('oppLineItem'+oppLineItem);
                oppLineItem.TotalPrice =(oppLineItem.Quantity / 1000) * oppLineItem.Unit_Price__c;
                //System.debug('oppLineItem'+oppLineItem);
                //oppLineItem.UnitPrice =  oppLineItem.UnitPrice / oppLineItem.Quantity;
            } else {
                System.debug('NON VCPM or CPM');
                System.debug(oppLineItem);
                oppLineItem.TotalPrice = oppLineItem.Quantity * oppLineItem.Unit_Price__c;
                //oppLineItem.UnitPrice =  oppLineItem.UnitPrice / oppLineItem.Quantity;
            }
        }
    }
    
    public static void establishSchedule(List<OpportunityLineItem> newOLIs) {
        List<OpportunityLineItemSchedule> listOlis = new List<OpportunityLineItemSchedule>();
        System.debug('>>>Inserting for : ' + newOLIs);    
        for(OpportunityLineItem oli: newOLIs) {
            Date startDate = oli.Start_Date__c;
            Date endOfMonth = startDate.addMonths(1);
            
            Date endDate = oli.End_Date__c;
            // if enddate exists before start date, take it to end of the month
            if(endDate < startDate) {
                endDate = endOfMonth;
            }
            Integer totalMonths = startDate.monthsBetween(endDate) + 1;
            Integer totalDays = startDate.daysBetween(endDate) + 1;
            Double dailyAmountQuantity = oli.Quantity / totalDays;
            Double dailyAmountRevenue = oli.TotalPrice / totalDays;
            endOfMonth = endOfMonth.toStartOfMonth();
            endOfMonth = endOfMonth.addDays(-1);
            Decimal runningTotalQuantity = 0;
            Decimal runningTotalRevenue = 0;
            for (Integer i = 1; i <= totalMonths; i++) {
                Integer numDaysInMonth;
                if (i == 1) {
                    numDaysInMonth = startDate.daysBetween(endOfMonth) + 1;
                } else {
                    Date firstDayOfMonth = endOfMonth.toStartOfMonth();
                    if (i == totalMonths) {
                        numDaysInMonth = firstDayOfMonth.daysBetween(endDate) + 1;
                    } else {
                        numDaysInMonth = firstDayOfMonth.daysBetween(endOfMonth) + 1;
                    }
                }
                Decimal scheduleQuantity = dailyAmountQuantity * numDaysInMonth;
                Decimal scheduleQuantityRounded = scheduleQuantity.setScale(0, RoundingMode.DOWN);
                runningTotalQuantity += scheduleQuantityRounded;
                Decimal scheduleRevenue = dailyAmountRevenue * numDaysInMonth;
                Decimal scheduleRevenueRounded = scheduleRevenue.setScale(2, RoundingMode.DOWN);
                runningTotalRevenue += scheduleRevenueRounded;
                if (i == totalMonths) {
                    Decimal leftOverQuantity = oli.Quantity - runningTotalQuantity;
                    scheduleQuantityRounded += leftOverQuantity;
                    Decimal leftOverRevenue = oli.TotalPrice - runningTotalRevenue;
                    scheduleRevenueRounded += leftOverRevenue;
                }
                Integer scheduleQuantityInteger = scheduleQuantityRounded.intValue();
                OpportunityLineItemSchedule olis = new OpportunityLineItemSchedule();
                olis.Type = 'Both';
                olis.OpportunityLineItemId = oli.Id;
                olis.ScheduleDate = endOfMonth;
                if(i == totalMonths) {
                    olis.Quantity = 1;

                }
                else {
                    olis.Quantity = 0;
                }
                olis.Revenue = scheduleRevenueRounded;
                listOlis.add(olis);
                endOfMonth = endOfMonth.addMonths(2);
                endOfMonth = endOfMonth.toStartOfMonth();
                endOfMonth = endOfMonth.addDays(-1);
            }
        }
        System.debug('>>>Inserting Schedules : ' + listOLIs);
        insert(listOlis);
    }
    
    /**
     * @description check if the given date is in the last quarter
     * @param dateToCompare given date
     * @param refDate reference date
     * @return boolean true if in last quarter, false otherwise
     */
    public static boolean isDateInPrevQuarter(Date dateToCompare, Date refDate) {
        boolean result = false;
        // find the quarter of the ref date
        Integer quarterRefDate = refDate.month();
        // find the quarter of the date to Compare
        Integer quarterForInputDate = dateToCompare.month();
        if(quarterRefDate == 1) {
            // first quarter of the next year
            if(refDate.year() - dateToCompare.year() == 1) {
                // last quarter of the previous year for the input date
                if(quarterForInputDate == 12) result = true;
            }
        }
        else {
            // for same year
            if(refDate.year() - dateToCompare.year() == 0) {
                integer diff = quarterRefDate - quarterForInputDate;
                if(diff > 0 && diff <= 3) result = true;
            }
        }
        return result;
    }
    
}