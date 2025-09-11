// SPDX-License-Identifier: ice License 1.0

import Foundation

final class FileTypeMapper {
    
    private static let mimeToFileType: [String: String] = [
        "application/pdf": "PDF",
        "application/msword": "Word",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document": "Word",
        "application/vnd.oasis.opendocument.text": "Text",
        "application/vnd.apple.pages": "Word",
        "application/vnd.ms-excel": "Spreadsheet",
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": "Spreadsheet",
        "application/vnd.oasis.opendocument.spreadsheet": "Spreadsheet",
        "application/vnd.apple.numbers": "Spreadsheet",
        "application/vnd.ms-powerpoint": "Presentation",
        "application/vnd.openxmlformats-officedocument.presentationml.presentation": "Presentation",
        "application/vnd.oasis.opendocument.presentation": "Presentation",
        "application/vnd.apple.keynote": "Presentation",
        "application/rtf": "Rich Text",
        "text/plain": "Text",
        "text/markdown": "Text",
        "text/csv": "Spreadsheet",
        "text/tab-separated-values": "Spreadsheet",
        "application/json": "Text",
        "application/xml": "Text",
        "text/xml": "Text",
        "text/html": "Text",
        "application/zip": "Archive",
        "application/x-zip-compressed": "Archive",
        "application/x-rar-compressed": "Archive",
        "application/vnd.rar": "Archive",
        "application/x-7z-compressed": "Archive",
        "application/x-tar": "Archive",
        "application/gzip": "Archive",
        "application/x-gzip": "Archive",
        "application/epub+zip": "Book",
        "application/vnd.amazon.ebook": "Book",
        "application/vnd.adobe.photoshop": "Image",
        "application/illustrator": "Image",
        "application/postscript": "Image",
        "application/x-indesign": "Design",
        "application/acad": "CAD",
        "application/dxf": "CAD",
        "model/stl": "3D Model",
        "model/obj": "3D Model",
        "application/x-sqlite3": "Database",
        "application/x-msaccess": "Database",
        "application/x-msdownload": "Application",
        "application/x-msi": "Installer",
        "application/vnd.android.package-archive": "Application",
        "application/x-ios-app": "Application",
        "application/x-apple-diskimage": "Disk Image",
        "application/x-debian-package": "Installer",
        "text/calendar": "Calendar",
        "text/vcard": "Contact",
        "application/x-x509-ca-cert": "Certificate",
        "application/octet-stream": "File",
        "binary/octet-stream": "File"
    ]
    
    /// Returns the user-friendly file type (extension) for a given MIME type
    /// Defaults to "File" if the MIME type is unknown or nil
    static func getFileType(mimeType: String?) -> String {
        guard let mime = mimeType else {
            return "File"
        }
        return mimeToFileType[mime] ?? "File"
    }
}
