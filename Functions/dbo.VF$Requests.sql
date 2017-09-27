SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[VF$Requests]
(	
	@X XML
)
RETURNS TABLE 
AS
RETURN 
(
   /*
    <Region code="" prvncode=""/>
    */
   WITH QXML AS
   (
      SELECT @X.query('Request').value('(Request/@rqid)[1]',         'BIGINT') AS RQID
            ,@X.query('Request').value('(Request/@rqtpcode)[1]',     'VARCHAR(3)') AS RQTP_CODE
            ,@X.query('Request').value('(Request/@rqttcode)[1]',     'VARCHAR(3)') AS RQTT_CODE
            ,@X.query('Request').value('(Request/@rqstrqid)[1]',     'BIGINT') AS RQST_RQID
            ,@X.query('Request').value('(Request/@regncode)[1]',     'VARCHAR(3)') AS REGN_CODE
            ,@X.query('Request').value('(Request/@prvncode)[1]',     'VARCHAR(3)') AS PRVN_CODE
            ,@X.query('Request').value('(Request/@subsys)[1]',       'SMALLINT') AS SUB_SYS
            ,@X.query('Request').value('(Request/@ssttmsttcode)[1]', 'SMALLINT') AS SSTT_MSTT_CODE
            ,@X.query('Request').value('(Request/@ssttcode)[1]',     'SMALLINT') AS SSTT_CODE
            ,@X.query('Request').value('(Request/@year)[1]',         'SMALLINT') AS [YEAR]
            ,@X.query('Request').value('(Request/@cycl)[1]',         'VARCHAR(3)') AS CYCL
            ,@X.query('Request').value('(Request/@cretby)[1]',       'VARCHAR(250)') AS CRET_BY
            ,@X.query('Request').value('(Request/@mdfyby)[1]',       'VARCHAR(250)') AS MDFY_BY
            ,@X.query('//Request_Row').value('(Request_Row/@fighfileno)[1]', 'BIGINT') AS FIGH_FILE_NO
            ,@X.query('Request').value('(Request/@fromrqstdate)[1]',       'DATE') AS FROM_RQST_DATE
            ,@X.query('Request').value('(Request/@torqstdate)[1]',       'DATE') AS TO_RQST_DATE
            ,@X.query('Request').value('(Request/@fromsavedate)[1]',       'DATE') AS FROM_SAVE_DATE
            ,@X.query('Request').value('(Request/@tosavedate)[1]',       'DATE') AS TO_SAVE_DATE
            ,@X.query('//Fighter').value('(Fighter/@cochcode)[1]',     'BIGINT') AS COCH_CODE
            ,@X.query('//Fighter').value('(Fighter/@cmbtcode)[1]',     'BIGINT') AS CBMT_CODE            
            ,@X.query('//Fighter').value('(Fighter/@mtodcode)[1]',     'BIGINT') AS MTOD_CODE
            ,@X.query('//Fighter').value('(Fighter/@ctgycode)[1]',     'BIGINT') AS CTGY_CODE
            ,@X.query('//Fighter').value('(Fighter/@frstname)[1]',     'NVARCHAR(250)') AS FRST_NAME
            ,@X.query('//Fighter').value('(Fighter/@lastname)[1]',     'NVARCHAR(250)') AS LAST_NAME
            ,@X.query('//Fighter').value('(Fighter/@suntbuntdeptorgncode)[1]',     'VARCHAR(2)') AS SUNT_BUNT_DEPT_ORGN_CODE
            ,@X.query('//Fighter').value('(Fighter/@suntbuntdeptcode)[1]',     'VARCHAR(2)') AS SUNT_BUNT_DEPT_CODE
            ,@X.query('//Fighter').value('(Fighter/@suntbuntcode)[1]',     'VARCHAR(2)') AS SUNT_BUNT_CODE
            ,@X.query('//Fighter').value('(Fighter/@suntcode)[1]',     'VARCHAR(4)') AS SUNT_CODE
            ,@X.query('//Fighter').value('(Fighter/@mbspstrtdate)[1]',     'DATE') AS MBSP_STRT_DATE
            ,@X.query('//Fighter').value('(Fighter/@mbspenddate)[1]',     'DATE') AS MBSP_END_DATE
   )
	SELECT R.*
	  FROM Request R 
	       LEFT OUTER JOIN Request_Row Rr ON (R.RQID = RR.RQST_RQID) 
	       LEFT OUTER JOIN Fighter F ON (Rr.FIGH_FILE_NO = F.FILE_NO) 
	       LEFT OUTER JOIN V#URFGA UR ON (UPPER(SUSER_NAME()) = UR.SYS_USER AND UR.REGN_PRVN_CODE = F.REGN_PRVN_CODE AND UR.REGN_CODE = F.REGN_CODE) 
	       LEFT OUTER JOIN V#UCFGA UC ON (UR.SYS_USER = UC.SYS_USER AND UC.CLUB_CODE = CASE WHEN R.RQTP_CODE IN ('001', '002') AND R.RQST_STAT = '001' THEN (SELECT P.CLUB_CODE FROM Fighter_Public P WHERE P.RQRO_RQST_RQID = R.RQID AND P.FIGH_FILE_NO = F.FILE_NO AND P.RECT_CODE = '001') ELSE F.CLUB_CODE_DNRM END)
	       , QXML QX
	 WHERE /*R.RQID = Rr.RQST_RQID
	   AND Rr.FIGH_FILE_NO = F.FILE_NO
	   AND UPPER(SUSER_NAME()) = UR.SYS_USER
	   AND UR.SYS_USER         = UC.SYS_USER
	   AND UR.REGN_PRVN_CODE   = F.REGN_PRVN_CODE
	   AND UR.REGN_CODE        = F.REGN_CODE
	   AND UC.CLUB_CODE        = CASE WHEN R.RQTP_CODE IN ('001', '002') AND R.RQST_STAT = '001' THEN (SELECT P.CLUB_CODE FROM Fighter_Public P WHERE P.RQRO_RQST_RQID = R.RQID AND P.FIGH_FILE_NO = F.FILE_NO AND P.RECT_CODE = '001') ELSE F.CLUB_CODE_DNRM END*/
	   (QX.RQID IS NULL OR QX.RQID = 0 OR R.RQID = QX.RQID)
	   AND (QX.RQTP_CODE IS NULL OR LEN(QX.RQTP_CODE) <> 3 OR R.RQTP_CODE = QX.RQTP_CODE)
	   AND (QX.RQTT_CODE IS NULL OR LEN(QX.RQTT_CODE) <> 3 OR R.RQTT_CODE = QX.RQTT_CODE)
	   AND (QX.RQST_RQID IS NULL OR QX.RQST_RQID = 0 OR R.RQST_RQID = QX.RQST_RQID)
	   AND (QX.REGN_CODE IS NULL OR LEN(QX.REGN_CODE) <> 3 OR R.REGN_CODE = QX.REGN_CODE)
	   AND (QX.PRVN_CODE IS NULL OR LEN(QX.PRVN_CODE) <> 3 OR R.REGN_PRVN_CODE = QX.PRVN_CODE)
	   AND (QX.SUB_SYS IS NULL OR Qx.SUB_SYS = 0 OR R.SUB_SYS = QX.SUB_SYS)
	   AND (QX.SSTT_MSTT_CODE IS NULL OR QX.SSTT_MSTT_CODE = 0 OR R.SSTT_MSTT_CODE = QX.SSTT_MSTT_CODE)
	   AND (QX.SSTT_CODE IS NULL OR QX.SSTT_CODE = 0 OR R.SSTT_CODE = QX.SSTT_CODE)
	   AND (QX.[YEAR] IS NULL OR QX.[YEAR] = 0 OR R.[YEAR] = QX.[YEAR])
	   AND (QX.CYCL IS NULL OR QX.CYCL = 0 OR R.CYCL = QX.CYCL)
	   AND (QX.CRET_BY IS NULL OR qx.CRET_BY = '' OR R.CRET_BY = QX.CRET_BY)
	   AND (QX.MDFY_BY IS NULL OR R.MDFY_BY = QX.MDFY_BY)
	   AND (QX.FIGH_FILE_NO IS NULL OR RR.FIGH_FILE_NO = QX.FIGH_FILE_NO)
	   AND (Qx.FROM_RQST_DATE IS NULL OR CAST(R.RQST_DATE AS DATE) >= Qx.FROM_RQST_DATE)
	   AND (Qx.TO_RQST_DATE IS NULL OR CAST(R.RQST_DATE AS DATE) <= Qx.TO_RQST_DATE)
	   AND (Qx.FROM_SAVE_DATE IS NULL OR CAST(R.SAVE_DATE AS DATE) >= Qx.FROM_SAVE_DATE)
	   AND (Qx.TO_SAVE_DATE IS NULL OR CAST(R.SAVE_DATE AS DATE) <= Qx.TO_SAVE_DATE)
	   AND (QX.COCH_CODE IS NULL OR F.COCH_FILE_NO_DNRM = QX.COCH_CODE)
	   AND (QX.CBMT_CODE IS NULL OR F.CBMT_CODE_DNRM = QX.CBMT_CODE)
	   AND (QX.MTOD_CODE IS NULL OR F.MTOD_CODE_DNRM = QX.MTOD_CODE)
	   AND (QX.CTGY_CODE IS NULL OR F.CTGY_CODE_DNRM = QX.CTGY_CODE)
	   AND (QX.FRST_NAME IS NULL OR F.NAME_DNRM LIKE N'%' + QX.FRST_NAME + N'%')
	   AND (QX.LAST_NAME IS NULL OR F.NAME_DNRM LIKE N'%' + QX.LAST_NAME + N'%')
	   AND (QX.SUNT_BUNT_DEPT_ORGN_CODE IS NULL OR F.SUNT_BUNT_DEPT_ORGN_CODE_DNRM = Qx.SUNT_BUNT_DEPT_ORGN_CODE)
	   AND (QX.SUNT_BUNT_DEPT_CODE IS NULL OR F.SUNT_BUNT_DEPT_CODE_DNRM = Qx.SUNT_BUNT_DEPT_CODE)
	   AND (QX.SUNT_BUNT_CODE IS NULL OR F.SUNT_BUNT_CODE_DNRM = Qx.SUNT_BUNT_CODE)
	   AND (QX.SUNT_CODE IS NULL OR F.SUNT_CODE_DNRM = Qx.SUNT_CODE)
	   AND (Qx.MBSP_STRT_DATE IS NULL OR F.MBSP_STRT_DATE >= Qx.MBSP_STRT_DATE)
	   AND (Qx.MBSP_END_DATE IS NULL OR F.MBSP_END_DATE <= Qx.MBSP_END_DATE)
)
GO
