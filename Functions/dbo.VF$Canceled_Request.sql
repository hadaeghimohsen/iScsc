SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[VF$Canceled_Request]
(	
	@Rqid BIGINT,
	@RqtpCode VARCHAR(3),
	@RqttCode VARCHAR(3),
	@MsttCode SMALLINT,
	@SsttCode SMALLINT,
	@RegnCode VARCHAR(3),
	@PrvnCode VARCHAR(3),
	@RqstRqid BIGINT
)
RETURNS TABLE 
AS
RETURN 
(	
	SELECT MSTT.CODE AS MSTT_CODE, MSTT.SUB_SYS, MSTT.MSTT_DESC
      ,SSTT.CODE AS SSTT_CODE, SSTT.SSTT_DESC, RQTP.CODE AS RQTP_CODE
      ,RQTP.RQTP_DESC, RQTT.CODE AS RQTT_CODE, RQTT.RQTT_DESC
      ,RQST.REGN_CODE, RQST.REGN_PRVN_CODE, RQST.RQST_RQID, RQST.RQID
      ,RQST.RQST_STAT, dbo.GET_MTST_U(RQST.RQST_DATE) AS RQST_DATE, RQST.SAVE_DATE, RQST.LETT_NO, RQST.LETT_DATE 
      ,RQST.LETT_OWNR, RQST.YEAR, RQST.CYCL
      ,RQST.CRET_BY, Dbo.GET_MTST_U(RQST.CRET_DATE) AS CRET_DATE, RQST.MDFY_BY, dbo.GET_MTST_U(RQST.MDFY_DATE) AS MDFY_DATE
FROM   dbo.Request AS RQST,
       dbo.Request_Type AS RQTP,
       dbo.Requester_Type AS RQTT,
       dbo.Sub_State AS SSTT,
       dbo.Main_State AS MSTT
WHERE RQST.RQST_STAT IN ('003')
  AND RQST.RQTP_CODE = RQTP.CODE
  AND RQST.RQTT_CODE = RQTT.CODE
  AND RQST.SSTT_MSTT_CODE = SSTT.MSTT_CODE AND RQST.SSTT_MSTT_SUB_SYS = SSTT.MSTT_SUB_SYS AND RQST.SSTT_CODE = SSTT.CODE
  AND SSTT.MSTT_CODE = MSTT.CODE AND SSTT.MSTT_SUB_SYS = MSTT.SUB_SYS
  AND ((@Rqid IS NULL) OR (RQST.RQID = @Rqid))
  AND ((@RqtpCode IS NULL) OR (RQST.RQTP_CODE = @RqtpCode))
  AND ((@RqttCode IS NULL) OR (RQST.RQTT_CODE = @RqttCode))
  AND ((@MsttCode IS NULL) OR (RQST.SSTT_MSTT_CODE = @MsttCode))
  AND ((@SsttCode IS NULL) OR (RQST.SSTT_CODE = @SsttCode))
  AND ((@RegnCode IS NULL) OR (RQST.REGN_CODE = @RegnCode))
  AND ((@PrvnCode IS NULL) OR (RQST.REGN_PRVN_CODE = @PrvnCode))
  AND ((@RqstRqid IS NULL) OR (RQST.RQST_RQID = @RqstRqid))
)
GO
