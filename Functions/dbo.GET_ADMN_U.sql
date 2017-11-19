SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GET_ADMN_U]
(
	-- Add the parameters for the function here
	@RqstDate DATE,
	@UserBy VARCHAR(250),
	@QuryType VARCHAR(3), -- 001 (MtodCode), 002 (CbmtCode)
	@CbmtCode BIGINT
)
RETURNS BIGINT
AS
BEGIN
   RETURN NULL;
	IF @QuryType = '001'
	BEGIN
	   RETURN (
	      SELECT COUNT(*)
	        FROM dbo.Payment_Detail pd, dbo.Payment p, dbo.Request r
	       WHERE pd.PYMT_CASH_CODE = p.CASH_CODE
	         AND pd.PYMT_RQST_RQID = p.RQST_RQID
	         AND p.RQST_RQID = r.RQID
	         AND r.RQST_STAT = '002'
	         AND r.RQTP_CODE NOT IN ('016')
	         AND CAST(pd.CRET_DATE AS DATE) = @RqstDate
	         AND pd.CRET_BY = @UserBy
	         AND pd.MTOD_CODE_DNRM IN 
	         (  
	            SELECT cm.MTOD_CODE
	              FROM dbo.Club_Method cm
	             WHERE cm.CODE = @CbmtCode
	         )
	   );
	END
	ELSE IF @QuryType = '002'
	BEGIN
	   RETURN (
	      SELECT COUNT(*)
	        FROM dbo.Payment_Detail pd, dbo.Payment p, dbo.Request r
	       WHERE pd.PYMT_CASH_CODE = p.CASH_CODE
	         AND pd.PYMT_RQST_RQID = p.RQST_RQID
	         AND p.RQST_RQID = r.RQID
	         AND r.RQST_STAT = '002'
	         AND r.RQTP_CODE NOT IN ('016')
	         AND CAST(pd.CRET_DATE AS DATE) = @RqstDate
	         AND pd.CRET_BY = @UserBy
	         AND pd.CBMT_CODE_DNRM = @CbmtCode	         
	   );
	END
	
	RETURN 0;
END
GO
