## Functional Requirements
| ID | Requirement |
|----|-------------|
| FR-1 | The system SHALL recursively discover every file with a `.py` extension beneath the supplied source directory, including files in nested directories. |
| FR-2 | The system SHALL generate `docs/generated/source-files.md` containing the discovered source-file paths relative to the supplied source directory. |
| FR-3 | The system SHALL list source-file paths in alphabetical order. |
| FR-4 | The system SHALL overwrite an existing `docs/generated/source-files.md` when generating a new listing. |
| FR-5 | The system SHALL generate a clear `No Python source files found` message in the Markdown document when the source directory contains no Python files. |

## Non-Functional Requirements
| ID | Requirement |
|----|-------------|
| NFR-1 | The generated document SHALL contain no absolute filesystem paths. |
| NFR-2 | The feature SHALL use only Python standard-library functionality and SHALL add no runtime dependencies. |

## Out of Scope
- Excluding any custom directories or file classes beyond selecting files with the `.py` extension.
- Printing the generated Markdown only to standard output instead of writing the specified document.
- Extracting symbols, documentation, or other metadata from Python files.
