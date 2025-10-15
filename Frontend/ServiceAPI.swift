//
//  ServiceAPI.swift
//  heart
//
//  Created by SAIL on 25/09/25.
//

import Foundation

struct ServiceAPI{
    
    static var baseURL = "http://14.139.187.229:8081/PDD-2025(9thmonth)/corecare"
    
    static var Register = baseURL+"register.php"
    
    static var Login = baseURL+"login.php"
    
    static var Heartbeat = baseURL+"heartbeat.php"
    
    static var Bp = baseURL+"bp.php"
    
    static var User = baseURL+"user.php"
    
    static var Weight = baseURL+"weight.php"
    
    static var Stress = baseURL+"stress.php"
    
    static var Moodwellness = baseURL+"mood_wellness.php"
    
    static var Daily = baseURL+"daily_report.php"
    
    static var Montly = baseURL+"monthly_report.php"
    
    static var Weekly = baseURL+"weekly_report.php"
    
    static var Riskassessment = baseURL+"risk_assessment.php"
    
    static var Forgot = baseURL+"forgot.php"
    
}

