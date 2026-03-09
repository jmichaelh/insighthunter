export interface ApiResponse<T> {
    T;
error?:  never;
}

export interface ApiError {
data?:   never;
error:   string;
status:  number;
}
 
export type ApiResult<T> = ApiResponse<T> | ApiError;

export interface KPISummary {
revenue:       number;
expenses:      number;
netIncome:     number;
cashOnHand:    number;
burnRate:      number;
runway:        number;          // months
period:        string;
}

export interface InsightCard {
id:       string;
type:     'warning' | 'opportunity' | 'info';
title:    string;
body:     string;
priority: 'high' | 'medium' | 'low';
cta?:     { label: string; href: string };
}
