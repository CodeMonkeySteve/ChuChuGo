db.things.drop()
for ( var i = 0; i < 10; ++i ) {
  db.things.save({
    x: parseInt(i + 1),
    _rev: ObjectId()
  })
  sleep(100)
}
