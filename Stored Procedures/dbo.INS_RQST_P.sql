SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[INS_RQST_P](
   @PRVN_CODE VARCHAR(3)
  ,@REGN_CODE VARCHAR(3)
  ,@RQST_RQID BIGINT
  ,@RQTP_CODE VARCHAR(3)
  ,@RQTT_CODE VARCHAR(3)
  ,@LETT_NO   VARCHAR(15)
  ,@LETT_DATE DATETIME
  ,@LETT_OWNR NVARCHAR(250)
  ,@Rqid      BIGINT OUT
)
AS
BEGIN
INSERT INTO [dbo].[Request]
           ([REGN_PRVN_CODE] 
           ,[REGN_CODE]
           ,[RQST_RQID]
           ,[RQTP_CODE]
           ,[RQTT_CODE]
           ,[LETT_NO]
           ,[LETT_DATE]
           ,[LETT_OWNR])
     VALUES
           (@PRVN_CODE
           ,@REGN_CODE
           ,@RQST_RQID
           ,@RQTP_CODE
           ,@RQTT_CODE
           ,@LETT_NO
           ,@LETT_DATE
           ,@LETT_OWNR);

   SELECT TOP 1 @Rqid = Rqid -- MAX(Rqid) 
   FROM Request
   WHERE REGN_PRVN_CODE = @Prvn_Code
     AND REGN_CODE = @Regn_Code
     AND RQTP_CODE = @Rqtp_Code
     AND RQTT_CODE = @Rqtt_Code
     AND CRET_BY   = UPPER(SUSER_NAME())
     AND SSTT_CODE = 1
     AND SSTT_MSTT_CODE = 1
     AND RQST_STAT = '001'
   ORDER BY RQST_DATE DESC;        
   
END;
GO
