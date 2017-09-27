SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[VF$InCome]
(	
    @FromDate DATE = '0001-01-01'
   ,@ToDate   DATE = '0001-01-01'
   ,@RqtpCode VARCHAR(3)
   ,@RqttCode VARCHAR(3)
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT 
   COALESCE((SELECT SUM(SUM_EXPN_PRIC)
      FROM Payment P, Request R 
     WHERE R.RQID = P.RQST_RQID
        AND R.RQST_STAT IN ('001', '002')
        AND (LEN(@RqtpCode) = 0 OR COALESCE(@RqtpCode, '000') = '000' OR R.RQTP_CODE = @RqtpCode)
        AND (LEN(@RqttCode) = 0 OR COALESCE(@RqttCode, '000') = '000' OR R.RQTT_CODE = @RqttCode)
        AND (COALESCE(@FromDate, '0001-01-01') = CAST('0001-01-01' AS DATE) OR @FromDate <= P.MDFY_DATE) 
        AND (COALESCE(@ToDate, '0001-01-01')   = CAST('0001-01-01' AS DATE) OR @ToDate >= P.MDFY_DATE) 
    ), 0) AS TOTL_PRIC,
   COALESCE((SELECT SUM(SUM_RCPT_EXPN_PRIC) 
      FROM Payment P, Request R 
     WHERE R.RQID = P.RQST_RQID
        AND R.RQST_STAT IN ('001', '002')
        AND (LEN(@RqtpCode) = 0 OR COALESCE(@RqtpCode, '000') = '000' OR R.RQTP_CODE = @RqtpCode)
        AND (LEN(@RqttCode) = 0 OR COALESCE(@RqttCode, '000') = '000' OR R.RQTT_CODE = @RqttCode)
        AND P.SUM_RCPT_EXPN_PRIC > 0
        AND (COALESCE(@FromDate, '0001-01-01') = CAST('0001-01-01' AS DATE) OR @FromDate <= P.MDFY_DATE) 
        AND (COALESCE(@ToDate, '0001-01-01')   = CAST('0001-01-01' AS DATE) OR @ToDate >= P.MDFY_DATE) 
    ), 0) AS RCPT_PRIC,
   COALESCE((SELECT SUM(SUM_EXPN_PRIC)
      FROM Payment P, Request R 
     WHERE R.RQID = P.RQST_RQID
        AND R.RQST_STAT IN ('001', '002')
        AND (LEN(@RqtpCode) = 0 OR COALESCE(@RqtpCode, '000') = '000' OR R.RQTP_CODE = @RqtpCode)
        AND (LEN(@RqttCode) = 0 OR COALESCE(@RqttCode, '000') = '000' OR R.RQTT_CODE = @RqttCode)
        AND P.SUM_RCPT_EXPN_PRIC = 0
        AND (COALESCE(@FromDate, '0001-01-01') = CAST('0001-01-01' AS DATE) OR @FromDate <= P.MDFY_DATE) 
        AND (COALESCE(@ToDate, '0001-01-01')   = CAST('0001-01-01' AS DATE) OR @ToDate >= P.MDFY_DATE) 
    ), 0) AS NOT_RCPT_PRIC
)
GO
