SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GET_ENDT_U]
(
	@AgopCode BIGINT, @Rwno BIGINT	
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @Rslt NVARCHAR(MAX) = '';
	
	DECLARE @AodtAgopCode BIGINT,
	        @AodtRwno BIGINT,
	        @AmntType VARCHAR(3),
	        @AmntTypeDesc NVARCHAR(255);
	        
	SELECT @AmntType = rg.AMNT_TYPE, 
          @AmntTypeDesc = d.DOMN_DESC
     FROM iScsc.dbo.Regulation rg, iScsc.dbo.[D$ATYP] d
    WHERE rg.TYPE = '001'
      AND rg.REGL_STAT = '002'
      AND rg.AMNT_TYPE = d.VALU;
              
	-- First find last element
	L$CheckLastElem:
	SELECT @AodtAgopCode = a.AGOP_CODE,
	       @AodtRwno = a.RWNO
	  FROM dbo.Aggregation_Operation_Detail a 
	 WHERE a.AODT_AGOP_CODE = @AgopCode AND a.AODT_RWNO = @Rwno;
	
	-- Has EXISTS child node then move to next node until find last element
	IF (@AodtAgopCode IS NOT NULL AND @AodtRwno IS NOT NULL)
	BEGIN 
	   SELECT @AgopCode = @AodtAgopCode, @Rwno = @AodtRwno;
	   SELECT @AodtAgopCode = NULL, @AodtRwno = NULL;
	   GOTO L$CheckLastElem;
	END
	
	DECLARE @TotlMint BIGINT = 0,
	        @TotlAmnt BIGINT = 0,
	        @TotlRcptAmnt BIGINT = 0;	
	
	-- process string
	L$ProcessMsg:
   SELECT @Rslt +=
          dbo.STR_FRMT_U(N'🟢 *{0}* : [ *{1} ({2}) {3}* ]' + CHAR(10) +
          N'⌚ مدت زمان ' + CHAR(10) +
          N'🟢 _{4}_ *{5}*' + CHAR(10) + 
          N'⏳ _{6}_ *{7}*' + CHAR(10),
          CAST(a.RWNO AS VARCHAR(20)) + N',' + 
          ei.EPIT_DESC + N',' + 
          m.MTOD_DESC + N',' + 
          cb.CTGY_DESC + N',' + 
          dbo.GET_MTOS_U(a.STRT_TIME) + N',' + 
          dbo.GET_TIME_U(a.STRT_TIME) + N',' + 
          dbo.GET_MTOS_U(a.END_TIME) + N',' + 
          dbo.GET_TIME_U(a.END_TIME) + N',' ) +
          CASE ISNULL(a.NUMB, 1) WHEN 1 THEN N'' ELSE CHAR(10) + CHAR(9) + dbo.STR_FRMT_U(N'👫 {0}, ', a.NUMB) END + 
          CASE ISNULL(a.TOTL_MINT_DNRM, 0) WHEN 0 THEN N'' ELSE CHAR(10) + CHAR(9) + dbo.STR_FRMT_U(N'▶ مدت زمان: *{0}* دقیقه ', a.TOTL_MINT_DNRM) END +
          CASE ISNULL(a.EXPR_MINT_NUMB, 0) WHEN 0 THEN N'' ELSE CHAR(10) + CHAR(9) + dbo.STR_FRMT_U(N'⏱ مدت درخواست زمان: *{0}* دقیقه ', a.EXPR_MINT_NUMB) END +
          CASE ISNULL(a.EXPN_PRIC, 0) WHEN 0 THEN N'' ELSE CHAR(10) + CHAR(9) + N'🧮 هزینه رزرو: *' + dbo.GET_NTOF_U(a.EXPN_PRIC) + N'* ' + @AmntTypeDesc END +
          CASE ISNULL(a.TOTL_BUFE_AMNT_DNRM, 0) WHEN 0 THEN N'' ELSE CHAR(10) + CHAR(9) + N'☕ هزینه بوفه: *' + dbo.GET_NTOF_U(a.TOTL_BUFE_AMNT_DNRM) + N'* ' + @AmntTypeDesc END +
          CASE ISNULL(a.TOTL_AMNT_DNRM, 0) WHEN 0 THEN N'' ELSE CHAR(10) + CHAR(9) + N'🧾 صورتحساب: *' + dbo.GET_NTOF_U(a.TOTL_AMNT_DNRM) + N'* ' + @AmntTypeDesc END + --CHAR(10) + CHAR(10) +
          CASE 
            WHEN (a.CASH_AMNT + a.POS_AMNT + a.DPST_AMNT) > 0 THEN 
                 --CHAR(10) + CHAR(10) +
                 N'💰 دریافتی صورتحساب: ' + 
                 CASE ISNULL(a.PYDS_AMNT, 0) WHEN 0 THEN N'' ELSE CHAR(10) + CHAR(9) + N'🏷️ تخفیف: *' + dbo.GET_NTOF_U(a.PYDS_AMNT) + N'* ' + @AmntTypeDesc END + 
                 CASE ISNULL(a.DPST_AMNT, 0) WHEN 0 THEN N'' ELSE CHAR(10) + CHAR(9) + N'🪙 مبلغ سپرده: *' + dbo.GET_NTOF_U(a.DPST_AMNT) + N'* ' + @AmntTypeDesc END + 
                 CASE ISNULL(a.CASH_AMNT, 0) WHEN 0 THEN N'' ELSE CHAR(10) + CHAR(9) + N'💵 مبلغ نقدی: *' + dbo.GET_NTOF_U(a.CASH_AMNT) + N'* ' + @AmntTypeDesc END + 
                 CASE ISNULL(a.POS_AMNT, 0) WHEN 0 THEN N'' ELSE CHAR(10) + CHAR(9) + N'💳 مبلغ کارتخوان: *' + dbo.GET_NTOF_U(a.POS_AMNT) + N'* ' + @AmntTypeDesc END --+ CHAR(10) + CHAR(10)
            ELSE N'' 
          END + CHAR(10) + CHAR(10),
          @AodtAgopCode = a.AODT_AGOP_CODE,
          @AodtRwno = a.AODT_RWNO,
          @TotlMint += a.TOTL_MINT_DNRM,
          @TotlAmnt += a.TOTL_AMNT_DNRM,
          @TotlRcptAmnt += (a.CASH_AMNT + a.POS_AMNT + a.DPST_AMNT) - (a.PYDS_AMNT)
    FROM iScsc.dbo.Aggregation_Operation_Detail a, iScsc.dbo.Expense e,
         iScsc.dbo.Expense_Type et, iScsc.dbo.Expense_Item ei,
         iScsc.dbo.Method m, iScsc.dbo.Category_Belt cb
   WHERE a.AGOP_CODE = @AgopCode
     AND a.RWNO = @Rwno
     AND a.EXPN_CODE = e.CODE
     AND e.EXTP_CODE = et.CODE
     AND et.EPIT_CODE = ei.CODE
     AND e.MTOD_CODE = m.CODE
     AND e.CTGY_CODE = cb.CODE;
   
   -- IF child node has exists
   IF @AodtAgopCode IS NOT NULL AND @AodtRwno IS NOT NULL
   BEGIN
      SELECT @AgopCode = @AodtAgopCode, @Rwno = @AodtRwno;      
      GOTO L$ProcessMsg;      
   END 
	
	RETURN @Rslt + CHAR(10) + 
	       dbo.STR_COPY_U(N'▪️', 13) + CHAR(10) + 
	       dbo.STR_FRMT_U(
	         N'⌚ {0}: *{1}* {2}',
	         N'مدت زمان کل' + ',' + CAST(@TotlMint AS VARCHAR(30)) + ',' + @AmntTypeDesc) + CHAR(10) + 
	       dbo.STR_FRMT_U(  
	         N'🧾 {0}: *{1}* {2}', 
	         N'صورتحساب کلی' + ',' + dbo.GET_NTOF2_U(@TotlAmnt, '.') + ',' + @AmntTypeDesc) + CHAR(10) + 
	       CASE 
            WHEN (@TotlRcptAmnt) > 0 THEN 
	             dbo.STR_FRMT_U( 
	               N'💰 {0}: *{1}* {2}',
	               N'مبلغ پرداخت شده تا الان' + ',' + dbo.GET_NTOF2_U(@TotlRcptAmnt, '.') + ',' + @AmntTypeDesc) + CHAR(10) + 
	             dbo.STR_FRMT_U( 
	               N'🪙 {0}: *{1}* {2}',
	               N'مانده حساب' + ',' + dbo.GET_NTOF2_U(@TotlAmnt - @TotlRcptAmnt, '.') + ',' + @AmntTypeDesc)   
	         ELSE N''
	       END;
END
GO
