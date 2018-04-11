setprocesspriority
camsystem = CameraSystem;
bhvsystem = BehaviorSystem;
bhvsystem.cameraObj = camsystem.cameraObj;
camsystem.behaviorSystemObj = bhvsystem;
start(bhvsystem)

