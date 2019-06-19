SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[VF$All_Info_Fighters] (
   @FileNo BIGINT
)RETURNS TABLE 
AS
RETURN
(
SELECT dbo.Fighter.FILE_NO, dbo.Fighter_Public.CHAT_ID AS CHAT_ID_DNRM, dbo.Fighter_Public.RWNO, dbo.Fighter.REGN_PRVN_CODE, dbo.Fighter.REGN_CODE, dbo.Fighter_Public.RQRO_RQST_RQID, dbo.Fighter_Public.NATL_CODE, dbo.Fighter_Public.GLOB_CODE, /*dbo.Fighter_Public.FMLY_NUMB,*/ dbo.Fighter_Public.POST_ADRS, 
       dbo.Fighter_Public.EMAL_ADRS, dbo.Fighter_Public.BRTH_DATE, dbo.Fighter_Public.CELL_PHON, dbo.Fighter_Public.TELL_PHON, dbo.Fighter_Public.COCH_DEG, dbo.Fighter_Public.GUDG_DEG,        
       dbo.Fighter_Public.TYPE, dbo.Fighter_Public.INSR_NUMB, dbo.Fighter_Public.INSR_DATE, dbo.Fighter_Public.FATH_NAME, dbo.Fighter_Public.LAST_NAME, dbo.Fighter_Public.FRST_NAME, dbo.Fighter_Public.COCH_FILE_NO,
       dbo.Diseases_Type.DISE_DESC, dbo.Method.MTOD_DESC, dbo.Category_Belt.CTGY_DESC, dbo.Club.NAME AS CLUB_NAME, dbo.D$FGTP.DOMN_DESC AS TYPE_DESC, 
       dbo.D$DEGR.DOMN_DESC AS COCH_DEGR, D$DEGR_1.DOMN_DESC AS GUGD_DEGR, dbo.D$SXTP.DOMN_DESC AS SEX_TYPE,
       dbo.D$ACTG.DOMN_DESC AS ACTV_TAG, dbo.Region.NAME AS REGN_NAME, dbo.Province.NAME AS PRVN_NAME, Dbo.D$BLOD.DOMN_DESC AS BLOD_GROP, dbo.Request_Type.RQTP_DESC, dbo.Fighter_Public.FNGR_PRNT,
       dbo.Fighter_Public.SUNT_BUNT_DEPT_ORGN_CODE, dbo.Fighter_Public.SUNT_BUNT_DEPT_CODE, dbo.Fighter_Public.SUNT_BUNT_CODE, dbo.Fighter_Public.SUNT_CODE,
       dbo.Organ.ORGN_DESC, dbo.Department.DEPT_DESC, dbo.Base_Unit.BUNT_DESC, dbo.Sub_Unit.SUNT_DESC,
       dbo.Fighter_Public.CORD_X,dbo.Fighter_Public.CORD_Y, dbo.Fighter_Public.SERV_NO, dbo.Fighter_Public.BRTH_PLAC, dbo.Fighter_Public.ISSU_PLAC, dbo.Fighter_Public.FATH_WORK, dbo.Fighter_Public.HIST_DESC,
       dbo.Fighter_Public.DPST_ACNT_SLRY_BANK,dbo.Fighter_Public.DPST_ACNT_SLRY, dbo.Fighter_Public.CBMT_CODE,
       dbo.Fighter_Public.MOM_CELL_PHON, dbo.Fighter_Public.MOM_TELL_PHON, dbo.Fighter_Public.MOM_CHAT_ID,
       dbo.Fighter_Public.DAD_CELL_PHON, dbo.Fighter_Public.DAD_TELL_PHON, dbo.Fighter_Public.DAD_CHAT_ID       
FROM   --dbo.Category_Belt INNER JOIN
       --dbo.Method ON dbo.Category_Belt.MTOD_CODE = dbo.Method.CODE LEFT OUTER JOIN
       dbo.Fighter INNER JOIN
       dbo.Fighter_Public ON dbo.Fighter.FILE_NO = dbo.Fighter_Public.FIGH_FILE_NO LEFT OUTER JOIN
       dbo.Club ON dbo.Fighter_Public.CLUB_CODE = dbo.Club.CODE LEFT OUTER JOIN
       dbo.Diseases_Type ON dbo.Fighter_Public.DISE_CODE = dbo.Diseases_Type.CODE LEFT OUTER JOIN
       dbo.D$FGTP ON dbo.Fighter_Public.TYPE = dbo.D$FGTP.VALU LEFT OUTER JOIN
       dbo.D$SXTP ON dbo.Fighter_Public.SEX_TYPE = dbo.D$SXTP.VALU LEFT OUTER JOIN
       dbo.Method  ON dbo.Method.CODE = dbo.Fighter_Public.MTOD_CODE LEFT OUTER JOIN
       dbo.Category_Belt ON dbo.Category_Belt.CODE = dbo.Fighter_Public.CTGY_CODE LEFT OUTER JOIN
       dbo.D$DEGR AS D$DEGR_1 ON dbo.Fighter_Public.GUDG_DEG = D$DEGR_1.VALU LEFT OUTER JOIN
       dbo.D$DEGR ON dbo.Fighter_Public.COCH_DEG = dbo.D$DEGR.VALU LEFT OUTER JOIN
       dbo.D$ACTG ON ISNULL(dbo.Fighter_Public.ACTV_TAG, '101') = dbo.D$ACTG.VALU LEFT OUTER JOIN
       dbo.D$BLOD ON dbo.Fighter_Public.BLOD_GROP = dbo.D$BLOD.VALU LEFT OUTER JOIN
       dbo.Request_Type ON (SELECT RQTP_CODE FROM Request WHERE RQID = dbo.Fighter_Public.RQRO_RQST_RQID) = dbo.Request_Type.CODE LEFT OUTER JOIN
       dbo.Region ON (dbo.Fighter.REGN_CODE = dbo.Region.CODE AND dbo.Fighter.REGN_PRVN_CODE = dbo.Region.PRVN_CODE AND dbo.Fighter.REGN_PRVN_CNTY_CODE = dbo.Region.PRVN_CNTY_CODE) LEFT OUTER JOIN
       dbo.Province ON (dbo.Fighter.REGN_PRVN_CODE = dbo.Province.CODE AND dbo.Fighter.REGN_PRVN_CNTY_CODE = dbo.Province.CNTY_CODE) LEFT OUTER JOIN
       
       dbo.Organ ON (dbo.Fighter_Public.SUNT_BUNT_DEPT_ORGN_CODE = dbo.Organ.CODE) LEFT OUTER JOIN
       dbo.Department ON (dbo.Fighter_Public.SUNT_BUNT_DEPT_CODE = dbo.Department.CODE AND dbo.Department.ORGN_CODE = dbo.Organ.CODE ) LEFT OUTER JOIN
       dbo.Base_Unit ON (dbo.Fighter_Public.SUNT_BUNT_CODE = dbo.Base_Unit.CODE AND dbo.Base_Unit.DEPT_ORGN_CODE = dbo.Organ.CODE AND dbo.Base_Unit.DEPT_CODE = dbo.Department.CODE) LEFT OUTER JOIN
       dbo.Sub_Unit ON (dbo.Fighter_Public.SUNT_CODE = dbo.Sub_Unit.CODE AND dbo.Sub_Unit.BUNT_DEPT_ORGN_CODE = dbo.Organ.CODE AND dbo.Sub_Unit.BUNT_DEPT_CODE = dbo.Department.CODE AND dbo.Sub_Unit.BUNT_CODE = dbo.Base_Unit.CODE)        
WHERE     (dbo.Fighter_Public.RECT_CODE = '004') AND (dbo.Fighter.CONF_STAT = '002')
  AND     (@FileNo IS NULL OR dbo.Fighter.FILE_NO = @FileNo)
)
GO
