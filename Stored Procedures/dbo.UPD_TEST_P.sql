SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_TEST_P]
	@Rqid BIGINT
  ,@RqroRwno SMALLINT
  ,@FileNo BIGINT
  ,@RectCode VARCHAR(3)
  ,@CrtfDate DATE
  ,@CrtfNumb NVARCHAR(20)
  ,@TestDate DATE
  ,@Rslt VARCHAR(3)
  ,@MtodCode BIGINT
  ,@CtgyCode BIGINT
  ,@GlobCode VARCHAR(20)
AS
BEGIN
   UPDATE Test
      SET CRTF_DATE = @CrtfDate
         ,CRTF_NUMB = @CrtfNumb
         ,TEST_DATE = @TestDate
         ,RSLT      = @Rslt
         ,CTGY_MTOD_CODE = @MtodCode
         ,CTGY_CODE = @CtgyCode
         ,GLOB_CODE = @GlobCode
    WHERE RQRO_RQST_RQID = @Rqid
      AND RQRO_RWNO = @RqroRwno
      AND FIGH_FILE_NO = @FileNo;      
END
GO
