db.things.remove()
for ( var i = 0; i < 10; ++i ) {
  db.things.save({
    x: parseInt(i + 1)
    //, _rev: new ObjectId
  })
  sleep(100)
}
