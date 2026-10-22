:ON ERROR EXIT
USE BlueStock;
GO
IF OBJECT_ID(N'dbo.DOI_SOAT_GIA_TRI', N'U') IS NULL
BEGIN
    :r database/schema/030_doi_soat_gia_tri.sql
END
GO
:r database/security/002_role_policy_20261022.sql
GO
