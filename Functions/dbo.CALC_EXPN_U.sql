SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[CALC_EXPN_U]
(
	@X XML
)
RETURNS BIGINT
AS
BEGIN
	-- local param
	DECLARE @Rqid BIGINT,
	        @ExpnCode BIGINT;
	
	SELECT @Rqid     = @x.query('//Request').value('(Request/@rqid)[1]', 'BIGINT'),
	       @ExpnCode = @x.query('//Request').value('(Request/@expncode)[1]', 'BIGINT');
	
	-- local var 
	DECLARE @ExpnAmnt BIGINT,
	        @CochFileNo BIGINT,
	        @CalcType VARCHAR(3),
	        @PrctValu FLOAT;
	
	-- نوع محاسبه اول بر اساس مبلغ دوره
	SELECT @CochFileNo = pd.FIGH_FILE_NO,
	       @CalcType = cc.CALC_TYPE,
	       @ExpnAmnt = pd.EXPN_PRIC * pd.QNTY,
	       @PrctValu = cc.PRCT_VALU
	  FROM dbo.Request r, dbo.Payment_Detail pd, dbo.Expense e, dbo.Calculate_Expense_Coach cc
	 WHERE r.RQID = @Rqid
	   AND r.RQID = pd.PYMT_RQST_RQID
	   AND pd.EXPN_CODE = @ExpnCode
	   AND pd.EXPN_CODE = e.CODE
	   AND e.MTOD_CODE = cc.MTOD_CODE
	   AND e.CTGY_CODE = cc.CTGY_CODE
	   AND cc.RQTP_CODE = r.RQTP_CODE
	   AND cc.RQTT_CODE = r.RQTT_CODE
	   AND cc.STAT = '002'
	   AND cc.CALC_EXPN_TYPE = '001' /* مبلغ دوره */;
	
	IF @CalcType = '001' -- %
	   SET @ExpnAmnt = @ExpnAmnt * @PrctValu / 100;
	ELSE IF @CalcType = '002' -- $
	   SET @ExpnAmnt = @PrctValu
	
	RETURN @ExpnAmnt;        
END
GO
