SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_TEST_P]
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
   INSERT INTO Test (RQRO_RQST_RQID, RQRO_RWNO, FIGH_FILE_NO, RECT_CODE, CRTF_DATE, CRTF_NUMB, TEST_DATE, RSLT, CTGY_MTOD_CODE, CTGY_CODE, GLOB_CODE)
   VALUES (@Rqid, @RqroRwno, @FileNo, @RectCode, @CrtfDate, @CrtfNumb, @TestDate, @Rslt, @MtodCode, @CtgyCode, @GlobCode);
END
GO
