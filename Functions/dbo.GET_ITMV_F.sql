SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GET_ITMV_F]
(@X xml)
RETURNS nvarchar(4000)
WITH EXEC AS CALLER
AS
BEGIN
DECLARE @Fileno BIGINT
       ,@ClubCode BIGINT
       ,@MbspRwno SMALLINT
       ,@FgdcCode BIGINT
       ,@AdvpCode BIGINT
       ,@TempItem VARCHAR(100);
   
  	SELECT @FileNo = @X.query('TemplateItemToText').value('(TemplateItemToText/@fileno)[1]', 'BIGINT')
  	      ,@MbspRwno = @X.query('TemplateItemToText').value('(TemplateItemToText/@mbsprwno)[1]', 'SMALLINT')
  	      ,@FgdcCode = @X.query('TemplateItemToText').value('(TemplateItemToText/@fgdccode)[1]', 'BIGINT')
  	      ,@AdvpCode = @X.query('TemplateItemToText').value('(TemplateItemToText/@advpcode)[1]', 'BIGINT')
	      ,@TempItem = @X.query('TemplateItemToText').value('(TemplateItemToText/@tempitem)[1]', 'VARCHAR(100)');
	
	SELECT @ClubCode = CLUB_CODE_DNRM
	  FROM dbo.Fighter
	 WHERE FILE_NO = @Fileno;
	
	RETURN 
	   CASE @TempItem
		   -- اطلاعات مشتریان
		   WHEN '{FIGH_FILE_NO}' THEN (SELECT CAST(@Fileno AS VARCHAR(30)))
		   WHEN '{FIGH_DEBT_DNRM}' THEN (SELECT REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, f.DEBT_DNRM), 1), '.00', '') FROM dbo.Fighter f WHERE f.FILE_NO = @Fileno)
		   WHEN '{FIGH_DPST_AMNT_DNRM}' THEN (SELECT REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, f.DPST_AMNT_DNRM), 1), '.00', '') FROM dbo.Fighter f WHERE f.FILE_NO = @Fileno)
		   WHEN '{FIGH_CONF_DATE}' THEN (SELECT dbo.GET_MTOS_U(f.CONF_DATE) FROM dbo.Fighter f WHERE f.FILE_NO = @Fileno)
		   WHEN '{FIGH_NAME_DNRM}' THEN (SELECT f.NAME_DNRM FROM dbo.Fighter f WHERE f.FILE_NO = @Fileno)
		   WHEN '{FIGH_FRST_NAME_DNRM}' THEN (SELECT f.FRST_NAME_DNRM FROM dbo.Fighter f WHERE f.FILE_NO = @Fileno)
		   WHEN '{FIGH_LAST_NAME_DNRM}' THEN (SELECT f.LAST_NAME_DNRM FROM dbo.Fighter f WHERE f.FILE_NO = @Fileno)
		   WHEN '{FIGH_FATH_NAME_DNRM}' THEN (SELECT f.FATH_NAME_DNRM FROM dbo.Fighter f WHERE f.FILE_NO = @Fileno)
		   WHEN '{FIGH_POST_ADRS_DNRM}' THEN (SELECT f.POST_ADRS_DNRM FROM dbo.Fighter f WHERE f.FILE_NO = @Fileno)
		   WHEN '{FIGH_SEX_TYPE_DNRM}' THEN (SELECT d.DOMN_DESC FROM dbo.Fighter f, dbo.[D$SXDC] d WHERE f.FILE_NO = @Fileno AND f.SEX_TYPE_DNRM = d.VALU)
		   WHEN '{FIGH_BRTH_DATE_DNRM}' THEN (SELECT dbo.GET_MTOS_U(f.BRTH_DATE_DNRM) FROM dbo.Fighter f WHERE f.FILE_NO = @Fileno)
		   WHEN '{FIGH_CELL_PHON_DNRM}' THEN (SELECT f.CELL_PHON_DNRM FROM dbo.Fighter f WHERE f.FILE_NO = @Fileno)
		   WHEN '{FIGH_TELL_PHON_DNRM}' THEN (SELECT f.TELL_PHON_DNRM FROM dbo.Fighter f WHERE f.FILE_NO = @Fileno)
		   WHEN '{FIGH_INSR_NUMB_DNRM}' THEN (SELECT f.INSR_NUMB_DNRM FROM dbo.Fighter f WHERE f.FILE_NO = @Fileno)
		   WHEN '{FIGH_INSR_DATE_DNRM}' THEN (SELECT dbo.GET_MTOS_U(f.INSR_DATE_DNRM) FROM dbo.Fighter f WHERE f.FILE_NO = @Fileno)
		   WHEN '{FIGH_FNGR_PRNT_DNRM}' THEN (SELECT f.FNGR_PRNT_DNRM FROM dbo.Fighter f WHERE f.FILE_NO = @Fileno)
		   WHEN '{FIGH_SUNT_CODE_DNRM}' THEN (SELECT su.SUNT_DESC FROM dbo.Fighter f, dbo.Sub_Unit su WHERE f.FILE_NO = @Fileno AND (f.SUNT_BUNT_DEPT_ORGN_CODE_DNRM + f.SUNT_BUNT_DEPT_CODE_DNRM + f.SUNT_BUNT_CODE_DNRM + f.SUNT_CODE_DNRM = su.BUNT_DEPT_ORGN_CODE + su.BUNT_DEPT_CODE + su.BUNT_CODE + su.CODE))
		   WHEN '{FIGH_SERV_NO_DNRM}' THEN (SELECT f.SERV_NO_DNRM FROM dbo.Fighter f WHERE f.FILE_NO = @Fileno)
		   WHEN '{FIGH_NATL_CODE_DNRM}' THEN (SELECT f.NATL_CODE_DNRM FROM dbo.Fighter f WHERE f.FILE_NO = @Fileno)
		   WHEN '{FIGH_GLOB_CODE_DNRM}' THEN (SELECT f.GLOB_CODE_DNRM FROM dbo.Fighter f WHERE f.FILE_NO = @Fileno)
		   WHEN '{FIGH_CHAT_ID_DNRM}' THEN (SELECT CAST(f.CHAT_ID_DNRM AS VARCHAR(30)) FROM dbo.Fighter f WHERE f.FILE_NO = @Fileno)
		   WHEN '{FIGH_MOM_CELL_PHON_DNRM}' THEN (SELECT f.MOM_CELL_PHON_DNRM FROM dbo.Fighter f WHERE f.FILE_NO = @Fileno)
		   WHEN '{FIGH_MOM_TELL_PHON_DNRM}' THEN (SELECT f.MOM_TELL_PHON_DNRM FROM dbo.Fighter f WHERE f.FILE_NO = @Fileno)
		   WHEN '{FIGH_MOM_CHAT_ID_DNRM}' THEN (SELECT CAST(f.MOM_CHAT_ID_DNRM AS VARCHAR(30)) FROM dbo.Fighter f WHERE f.FILE_NO = @Fileno)
		   WHEN '{FIGH_DAD_CELL_PHON_DNRM}' THEN (SELECT f.DAD_CELL_PHON_DNRM FROM dbo.Fighter f WHERE f.FILE_NO = @Fileno)
		   WHEN '{FIGH_DAD_TELL_PHON_DNRM}' THEN (SELECT f.DAD_TELL_PHON_DNRM FROM dbo.Fighter f WHERE f.FILE_NO = @Fileno)
		   WHEN '{FIGH_DAD_CHAT_ID_DNRM}' THEN (SELECT CAST(f.DAD_CHAT_ID_DNRM AS VARCHAR(30)) FROM dbo.Fighter f WHERE f.FILE_NO = @Fileno)
		   WHEN '{FIGH_RTNG_NUMB_DNRM}' THEN (SELECT CAST(f.RTNG_NUMB_DNRM AS VARCHAR(2)) FROM dbo.Fighter f WHERE f.FILE_NO = @Fileno)
		   WHEN '{FIGH_ATTN_NUMB_OF_YEAR}' THEN (SELECT CAST(COUNT(*) AS VARCHAR(10)) FROM dbo.Attendance a, dbo.Settings s WHERE a.CLUB_CODE = s.CLUB_CODE AND a.FIGH_FILE_NO = @Fileno AND a.ATTN_STAT = '002' AND (s.REST_ATTN_NUMB_BY_YEAR = '001' OR (s.REST_ATTN_NUMB_BY_YEAR = '002' AND YEAR(a.ATTN_DATE) = YEAR(GETDATE()))))
		   -- اطلاعات دوره مشتری
		   WHEN '{MBSP_END_DATE}' THEN (SELECT dbo.GET_MTOS_U(sp.END_DATE) FROM dbo.Member_Ship sp WHERE sp.FIGH_FILE_NO = @Fileno AND sp.RWNO = @MbspRwno AND sp.RECT_CODE = '004')
         WHEN '{MBSP_NUMB_OF_ATTN_MONT}' THEN (SELECT CAST(sp.NUMB_OF_ATTN_MONT AS VARCHAR(10)) FROM dbo.Member_Ship sp WHERE sp.FIGH_FILE_NO = @Fileno AND sp.RWNO = @MbspRwno AND sp.RECT_CODE = '004')
         WHEN '{MBSP_NUMB_OF_DAYS_DNRM}' THEN (SELECT CAST(sp.NUMB_OF_DAYS_DNRM AS VARCHAR(10)) FROM dbo.Member_Ship sp WHERE sp.FIGH_FILE_NO = @Fileno AND sp.RWNO = @MbspRwno AND sp.RECT_CODE = '004')
         WHEN '{MBSP_NUMB_OF_MONT_DNRM}' THEN (SELECT CAST(sp.NUMB_OF_MONT_DNRM AS VARCHAR(10)) FROM dbo.Member_Ship sp WHERE sp.FIGH_FILE_NO = @Fileno AND sp.RWNO = @MbspRwno AND sp.RECT_CODE = '004')
         WHEN '{MBSP_RTNG_NUMB_DNRM}' THEN (SELECT CAST(sp.RTNG_NUMB_DNRM AS VARCHAR(2)) FROM dbo.Member_Ship sp WHERE sp.FIGH_FILE_NO = @Fileno AND sp.RWNO = @MbspRwno AND sp.RECT_CODE = '004')
         WHEN '{MBSP_RWNO}' THEN (SELECT CAST(@MbspRwno AS VARCHAR(10)))
         WHEN '{MBSP_STRT_DATE}' THEN (SELECT dbo.GET_MTOS_U(sp.STRT_DATE) FROM dbo.Member_Ship sp WHERE sp.FIGH_FILE_NO = @Fileno AND sp.RWNO = @MbspRwno AND sp.RECT_CODE = '004')
         WHEN '{MBSP_SUM_ATTN_MONT_DNRM}' THEN (SELECT CAST(sp.SUM_ATTN_MONT_DNRM AS VARCHAR(10)) FROM dbo.Member_Ship sp WHERE sp.FIGH_FILE_NO = @Fileno AND sp.RWNO = @MbspRwno AND sp.RECT_CODE = '004')
         WHEN '{MBSP_NUMB_DAY_CHRG}' THEN (SELECT CASE sp.NUMB_OF_ATTN_MONT WHEN '0' THEN CAST(sp.NUMB_OF_DAYS_DNRM AS VARCHAR(10)) + N' ' + N'روز' ELSE CAST(sp.NUMB_OF_ATTN_MONT AS VARCHAR(10)) + N' ' + N' جلسه' END FROM dbo.Member_Ship sp WHERE sp.FIGH_FILE_NO = @Fileno AND sp.RWNO = @MbspRwno AND sp.RECT_CODE = '004')
         -- اطلاعات مجموعه
         WHEN '{CLUB_CELL_PHON}' THEN (SELECT CELL_PHON FROM dbo.Club WHERE CODE = @ClubCode)
         WHEN '{CLUB_CLUB_DESC}' THEN (SELECT CLUB_DESC FROM dbo.Club WHERE CODE = @ClubCode)
         WHEN '{CLUB_ECON_CODE}' THEN (SELECT ECON_CODE FROM dbo.Club WHERE CODE = @ClubCode)
         WHEN '{CLUB_EMAL_ADRS}' THEN (SELECT EMAL_ADRS FROM dbo.Club WHERE CODE = @ClubCode)
         WHEN '{CLUB_NAME}' THEN (SELECT NAME FROM dbo.Club WHERE CODE = @ClubCode)
         WHEN '{CLUB_POST_ADRS}' THEN (SELECT POST_ADRS FROM dbo.Club WHERE CODE = @ClubCode)
         WHEN '{CLUB_TELL_PHON}' THEN (SELECT TELL_PHON FROM dbo.Club WHERE CODE = @ClubCode)
         WHEN '{CLUB_WEB_SITE}' THEN (SELECT WEB_SITE FROM dbo.Club WHERE CODE = @ClubCode)
         WHEN '{CLUB_ZIP_CODE}' THEN (SELECT ZIP_CODE FROM dbo.Club WHERE CODE = @ClubCode)
         -- اطلاعات عمومی سیستم
         WHEN '{GLOB_CRNT_YEAR}' THEN (SELECT LEFT(dbo.GET_MTOS_U(GETDATE()), 4))
         WHEN '{GLOB_CRNT_USER}' THEN (SELECT User_Name FROM V#Users vu WHERE vu.USER_DB = UPPER(SUSER_NAME()))
         WHEN '{GLOB_CRNT_DATE_TIME}' THEN (SELECT dbo.GET_MTOS_U(GETDATE()) + N' ' + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5)))
         WHEN '{GLOB_CRNT_DATE}' THEN (SELECT dbo.GET_MTOS_U(GETDATE()))
         WHEN '{GLOB_CRNT_TIME}' THEN (SELECT CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5)))
         -- اطلاعات کاربر
         WHEN '{USER_CELL_PHON}' THEN (SELECT ISNULL(CELL_PHON, '*') FROM dbo.V#Users WHERE USER_DB = UPPER(SUSER_NAME()))
         WHEN '{USER_EMAL_ADRS}' THEN (SELECT ISNULL(EMAL_ADRS, '*') FROM dbo.V#Users WHERE USER_DB = UPPER(SUSER_NAME()))
         WHEN '{USER_TELL_PHON}' THEN (SELECT ISNULL(TELL_PHON, '*') FROM dbo.V#Users WHERE USER_DB = UPPER(SUSER_NAME()))
         WHEN '{USER_USER_DB}' THEN (SELECT ISNULL(USER_DB, '*') FROM dbo.V#Users WHERE USER_DB = UPPER(SUSER_NAME()))
         WHEN '{USER_USER_NAME}' THEN (SELECT ISNULL([USER_NAME], '*') FROM dbo.V#Users WHERE USER_DB = UPPER(SUSER_NAME()))
         WHEN '{USER_VOIP_NUMB}' THEN (SELECT ISNULL(VOIP_NUMB, '*') FROM dbo.V#Users WHERE USER_DB = UPPER(SUSER_NAME()))
         -- اطلاعات کد تخفیف مشتریان
         WHEN '{FGDC_DISC_CODE}' THEN (SELECT DISC_CODE FROM dbo.Fighter_Discount_Card WHERE CODE = @FgdcCode)
         WHEN '{FGDC_EXPR_DATE}' THEN (SELECT dbo.GET_MTOS_U(EXPR_DATE) FROM dbo.Fighter_Discount_Card WHERE CODE = @FgdcCode)
         WHEN '{FGDC_DSCT_AMNT}' THEN (SELECT CASE DSCT_TYPE WHEN '001' THEN CAST(DSCT_AMNT AS NVARCHAR(50)) WHEN '002' THEN REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, DSCT_AMNT), 1), '.00', '') END FROM dbo.Fighter_Discount_Card WHERE CODE = @FgdcCode)
         WHEN '{FGDC_DSCT_TYPE}' THEN (SELECT CASE DSCT_TYPE WHEN '001' THEN N'%' WHEN '002' THEN (SELECT d.DOMN_DESC FROM dbo.Regulation r, dbo.[D$ATYP] d WHERE r.AMNT_TYPE = d.VALU AND r.REGL_STAT = '002' AND r.[TYPE] = '001') END FROM dbo.Fighter_Discount_Card WHERE CODE = @FgdcCode)
         WHEN '{FGDC_MTOD_CODE}' THEN ISNULL((SELECT m.MTOD_DESC FROM dbo.Method m, dbo.Fighter_Discount_Card d WHERE d.CODE = @FgdcCode AND d.MTOD_CODE = m.CODE), '')
         WHEN '{FGDC_CTGY_CODE}' THEN ISNULL((SELECT c.CTGY_DESC FROM dbo.Category_Belt c, dbo.Fighter_Discount_Card d WHERE d.CODE = @FgdcCode AND d.CTGY_CODE = c.CODE), '')
         WHEN '{FGDC_RQTP_CODE}' THEN ISNULL((SELECT r.RQTP_DESC FROM dbo.Request_Type r, dbo.Fighter_Discount_Card d WHERE d.CODE = @FgdcCode AND d.RQTP_CODE = r.CODE), '')
         -- اطلاعات پارامتر تبلیغات
         WHEN '{ADVP_DISC_CODE}' THEN (SELECT DISC_CODE FROM dbo.Advertising_Parameter WHERE CODE = @AdvpCode)
         WHEN '{ADVP_EXPR_DATE}' THEN (SELECT dbo.GET_MTOS_U(EXPR_DATE) FROM dbo.Advertising_Parameter WHERE CODE = @AdvpCode)
         WHEN '{ADVP_DSCT_AMNT}' THEN (SELECT CASE DSCT_TYPE WHEN '001' THEN CAST(DSCT_AMNT AS NVARCHAR(50)) WHEN '002' THEN REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, DSCT_AMNT), 1), '.00', '') END FROM dbo.Advertising_Parameter WHERE CODE = @AdvpCode)
         WHEN '{ADVP_DSCT_TYPE}' THEN (SELECT CASE DSCT_TYPE WHEN '001' THEN N'%' WHEN '002' THEN (SELECT d.DOMN_DESC FROM dbo.Regulation r, dbo.[D$ATYP] d WHERE r.AMNT_TYPE = d.VALU AND r.REGL_STAT = '002' AND r.[TYPE] = '001') END FROM dbo.Advertising_Parameter WHERE CODE = @AdvpCode)
         WHEN '{ADVP_MTOD_CODE}' THEN ISNULL((SELECT m.MTOD_DESC FROM dbo.Method m, dbo.Advertising_Parameter d WHERE d.CODE = @AdvpCode AND d.MTOD_CODE = m.CODE), '')
         WHEN '{ADVP_CTGY_CODE}' THEN ISNULL((SELECT c.CTGY_DESC FROM dbo.Category_Belt c, dbo.Advertising_Parameter d WHERE d.CODE = @AdvpCode AND d.CTGY_CODE = c.CODE), '')
         WHEN '{ADVP_RQTP_CODE}' THEN ISNULL((SELECT r.RQTP_DESC FROM dbo.Request_Type r, dbo.Advertising_Parameter d WHERE d.CODE = @AdvpCode AND d.RQTP_CODE = r.CODE), '')
	   END;
END
GO
