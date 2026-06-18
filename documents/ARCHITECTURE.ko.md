# 아키텍처 문서

## 결론

Free PDF Editor v0.0.1은 **SwiftUI 앱 + AppKit PDFView 브리지 + PDFKit annotation 편집 엔진**으로 구성되어 있습니다. 전체 PDF 엔진을 직접 만들지 않고, PDFKit이 제공하는 렌더링/선택/저장 기능 위에 편집 UX를 구현합니다.

## 구조

```text
Sources/FreePDFEditor/
├── App
│   └── FreePDFEditorApp.swift
├── Models
│   ├── EditorTool.swift
│   ├── ReadingMode.swift
│   ├── ReplacementDraft.swift
│   └── SignatureItem.swift
├── Services
│   ├── PDFEditorModel.swift
│   └── PDFImageAnnotation.swift
├── Stores
│   └── SignatureStore.swift
├── Views
│   ├── ContentView.swift
│   ├── PDFKitEditorView.swift
│   ├── InspectorView.swift
│   ├── SignatureManagerView.swift
│   ├── SignatureCanvasView.swift
│   └── ThumbnailSidebarView.swift
└── Support
    └── AppMetadata.swift
```

## 핵심 컴포넌트

| 컴포넌트 | 역할 |
|---|---|
| `PDFEditorModel` | 문서, URL, 현재 도구, 선택 annotation, 저장 상태, 텍스트 교체 초안 관리 |
| `PDFKitEditorView` | `PDFView`를 SwiftUI에 연결하고 마우스 이벤트를 PDF 좌표로 변환 |
| `EditorPDFView` | 텍스트 hit-testing, annotation 추가, 서명 배치, 도형 드래그 처리 |
| `AnnotationSelectionOverlay` | 삽입된 annotation 선택, 이동, 리사이즈, 삭제 처리 |
| `SignatureStore` | 사용자 서명 PNG 저장 및 선택 상태 관리 |
| `SignatureCanvasView` | 마우스/트랙패드 기반 서명 드로잉 캔버스 |

## 데이터 흐름

```text
사용자 입력
  ↓
PDFKitEditorView / EditorPDFView
  ↓
PDFKit 좌표 변환 및 annotation 생성
  ↓
PDFEditorModel 상태 갱신
  ↓
SwiftUI inspector/sidebar 갱신
  ↓
PDFDocument.dataRepresentation 저장
```

## 저장 방식

- 일반 저장: PDFKit annotation을 편집 가능한 상태로 보존합니다.
- Flattened export: `PDFDocumentWriteOption.burnInAnnotationsOption`으로 annotation을 시각적으로 페이지에 굳힙니다.

## 한계

PDF 본문 텍스트를 내부 content stream에서 삭제하는 기능은 아직 없습니다. 현재 텍스트 교체는 cover annotation과 replacement text annotation을 이용한 시각적 교체입니다.
