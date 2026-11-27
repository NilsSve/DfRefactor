// PUBLIC login encryption key for the DFRefactor workspace - committed on purpose (2026-11-27).
// DFRefactor stores no passwords: this key is only compiled in because the DUF library's SQL
// connection class #Includes it. It protects NOTHING here - never reuse it in a workspace that does
// store passwords; let the Studio generate that workspace its own.
Set psEncryptPassword to "kkAWYe*cAJ#zNKi@qiGninVkme8tNQC@UDsmJ)fx"
