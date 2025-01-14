## iOS - wanted - GyroData

### 팀원

[Hugh](https://github.com/Hugh-github)
1. CoreData 구현 및 Unit Test 진행
2. MainViewController 구현

[보리사랑](https://github.com/yusw10)
1. FileManager 구현
2. RecordViewController 구현

---
### 폴더 구조
```
.
└── GyroData/
    ├── Source/
    │   ├── AppDelegate
    │   ├── SceneDelegate
    │   ├── Util/
    │   │   ├── Extension/
    │   │   │   └── Type+Extension
    │   │   └── Manager/
    │   │       ├── DateFormatterManager/
    │   │       │   └── DateFormatterManager
    │   │       ├── MotionManager/
    │   │       │   └── MotionManager
    │   │       ├── FileManager/
    │   │       │   └── FileManager
    │   │       └── CoreData/
    │   │           ├── GyroModel
    │   │           ├── CoreDataStack
    │   │           └── GyroStore
    │   ├── Model/
    │   │   ├── MeasureData
    │   │   ├── MotionData
    │   │   ├── GraphPoint
    │   │   └── SensorType
    │   ├── Controller/
    │   │   ├── MainViewController
    │   │   └── RecordViewController
    │   └── View/
    │       ├── FirstTableViewCell
    │       └── GraphView
    ├── Resource/
    │   ├── Info
    │   ├── LaunchScreen/
    │   │   └── LaunchScreen
    │   └── Asset/
    │       └── Asset
    └── GyroDataTests/
        └── GyroDataTests
```

### MVC
+ View에 필요한 로직을 제외하고는 따로 타입을 만들어 처리
+ Controller간 Event 처리는 Delegate를 사용해 구현

### Type
#### CoreDataStack
- CoreData에 대한 Unit Test를 진행하기 위해 in-memory를 방식을 선택 가능하도록 구현
    - 저장되는 위치를 /dev/null로 설정하여 구현
- 싱글톤 패턴을 이용해 on-disk 방식의 CoreDataStack 구현

#### GyroStore
- CoreData에 대한 CRUD 기능 구현

#### FileManager
- Foundation의 FileManager를 extension으로 확장하여 구현
- `MeasureDataSavingInFileManagerProtocol`로 추상화 
- 측정한 데이터 묶음을 Documentaion의 UserDomain 영역에 저장
- save, load, remove 기능 구현

#### MotionManager
- CoreMotion 프레임워크에서 제공하는 CMMotionManager 기능을 사용하는 싱글톤 객체
- 함수 파라미터로 주입받는 센싱데이터의 타입에 따라 측정을 시작
    - 측정한 데이터는 escaping closure로 호출부에 반환
- 측정 데이터가 Double 타입이기에 소수점 세자리로 표현하기 위해 `CMAccelerometerData`와 `CMGyroData` 타입에 변환 메서드 확장

### Controller
#### MainViewController
- Delegate를 채택하여 RecordViewController에서 보내주는 데이터를 CoreData에 저장
- DiffableDataSource를 이용해 TableView 구현

#### RecordViewController
- Segment Controller
    - 현재 선택한 측정 타입을 SegmentController를 사용하여 저장
- UIButton
    - MotionManager로부터 측정된 데이터를 completionHandler로 받아와 GraphView의 drawNewData 메서드 호출 60초치의 최대 데이터 수량이 측정되면 측정 종료
    - 저장 버튼 터치시 FileManager를 통해 현재까지 측정된 데이터가 json 타입으로 저장되며, delegate를 통해 현재 측정값의 대표값이 ViewController로 전달
- 내부 데이터
    - 측정 시작 순간부터 인터벌 마다 측정된 `MeasureData` 타입의 배열을 데이터로 소유
    - GraphView의 x 좌표로 사용하기 위한 `currentX` 프로퍼티에 recordData가 추가될때마다 업데이트하고 이를 drawNewData의 파라미터로 사용


### View
#### FirstTableViewCell
- MainViewController의 TableView에서 사용할 Cell 구현

#### GraphView
- `UIBezierPath`를 이용해 측정 데이터를 Layer에 표현
- GraphView의 높이 절반값을 기준점으로 표현
